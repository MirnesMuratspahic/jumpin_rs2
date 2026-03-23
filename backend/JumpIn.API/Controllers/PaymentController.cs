using JumpIn.Models.DTOs;
using JumpIn.Models.Messages;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.Database;
using JumpIn.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Stripe;
using Stripe.Checkout;

namespace JumpIn.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class PaymentController : ControllerBase
    {
        private readonly JumpInDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly IPaymentService _paymentService;
        private readonly IMessagePublisher _messagePublisher;

        public PaymentController(JumpInDbContext context, IConfiguration configuration, IPaymentService paymentService, IMessagePublisher messagePublisher)
        {
            _context = context;
            _configuration = configuration;
            _paymentService = paymentService;
            _messagePublisher = messagePublisher;
            StripeConfiguration.ApiKey = _configuration["Stripe:SecretKey"];
        }

        [HttpGet("history")]
        public async Task<IActionResult> GetPaymentHistory([FromQuery] PaymentSearchObject search)
        {
            return Ok(await _paymentService.GetPagedAsync(search));
        }

        [HttpGet("history/{id}")]
        public IActionResult GetPaymentById(int id)
        {
            return Ok(_paymentService.GetById(id));
        }

        [HttpPost("create-checkout-session/{userId}")]
        public async Task<IActionResult> CreateCheckoutSession(int userId)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null || user.IsDeleted)
                return NotFound(new { message = "User not found." });

            if (user.IsVip)
                return BadRequest(new { message = "User already has an active VIP subscription." });

            // Create or retrieve Stripe customer
            var customerService = new CustomerService();
            string customerId;

            if (!string.IsNullOrEmpty(user.StripeCustomerId))
            {
                customerId = user.StripeCustomerId;
            }
            else
            {
                var customerOptions = new CustomerCreateOptions
                {
                    Email = user.Email,
                    Name = $"{user.FirstName} {user.LastName}",
                    Metadata = new Dictionary<string, string>
                    {
                        { "userId", user.Id.ToString() }
                    }
                };
                var customer = await customerService.CreateAsync(customerOptions);
                customerId = customer.Id;

                user.StripeCustomerId = customerId;
                await _context.SaveChangesAsync();
            }

            var currency = _configuration["Stripe:Currency"] ?? "bam";
            var priceAmount = long.Parse(_configuration["Stripe:VipPriceAmountInCents"] ?? "2000");

            var options = new SessionCreateOptions
            {
                Customer = customerId,
                PaymentMethodTypes = new List<string> { "card" },
                LineItems = new List<SessionLineItemOptions>
                {
                    new SessionLineItemOptions
                    {
                        PriceData = new SessionLineItemPriceDataOptions
                        {
                            Currency = currency,
                            UnitAmount = priceAmount,
                            Recurring = new SessionLineItemPriceDataRecurringOptions
                            {
                                Interval = "month",
                            },
                            ProductData = new SessionLineItemPriceDataProductDataOptions
                            {
                                Name = "JumpIn VIP Membership",
                                Description = "Monthly VIP subscription - highlighted ads and priority listing",
                            },
                        },
                        Quantity = 1,
                    },
                },
                Mode = "subscription",
                SuccessUrl = $"{Request.Scheme}://{Request.Host}/api/Payment/success?session_id={{CHECKOUT_SESSION_ID}}",
                CancelUrl = $"{Request.Scheme}://{Request.Host}/api/Payment/cancel",
                Metadata = new Dictionary<string, string>
                {
                    { "userId", user.Id.ToString() }
                }
            };

            var service = new SessionService();
            var session = await service.CreateAsync(options);

            return Ok(new { url = session.Url });
        }

        [AllowAnonymous]
        [HttpGet("success")]
        public async Task<IActionResult> Success([FromQuery] string session_id)
        {
            var sessionService = new SessionService();
            var session = await sessionService.GetAsync(session_id);

            if (session.PaymentStatus == "paid" || session.Status == "complete")
            {
                var userIdStr = session.Metadata["userId"];
                if (int.TryParse(userIdStr, out int userId))
                {
                    var user = await _context.Users.FindAsync(userId);
                    if (user != null)
                    {
                        user.IsVip = true;
                        user.VipActivatedAt = DateTime.UtcNow;
                        user.VipExpiresAt = DateTime.UtcNow.AddMonths(1);
                        user.StripeSubscriptionId = session.SubscriptionId;
                        await _context.SaveChangesAsync();
                    }
                }
            }

            return Content(
                "<html><body style='font-family:sans-serif;text-align:center;padding:50px;'>" +
                "<h1 style='color:#4CAF50;'>Payment Successful!</h1>" +
                "<p>Your VIP membership has been activated.</p>" +
                "<p>You can close this page and return to the app.</p>" +
                "</body></html>",
                "text/html");
        }

        [AllowAnonymous]
        [HttpGet("cancel")]
        public IActionResult Cancel()
        {
            return Content(
                "<html><body style='font-family:sans-serif;text-align:center;padding:50px;'>" +
                "<h1 style='color:#f44336;'>Payment Cancelled</h1>" +
                "<p>Your VIP subscription was not activated.</p>" +
                "<p>You can close this page and return to the app.</p>" +
                "</body></html>",
                "text/html");
        }

        [AllowAnonymous]
        [HttpPost("webhook")]
        public async Task<IActionResult> Webhook()
        {
            var json = await new StreamReader(HttpContext.Request.Body).ReadToEndAsync();
            var webhookSecret = _configuration["Stripe:WebhookSecret"];

            try
            {
                Event stripeEvent;

                if (!string.IsNullOrEmpty(webhookSecret))
                {
                    stripeEvent = EventUtility.ConstructEvent(
                        json,
                        Request.Headers["Stripe-Signature"],
                        webhookSecret);
                }
                else
                {
                    stripeEvent = EventUtility.ParseEvent(json);
                }

                switch (stripeEvent.Type)
                {
                    case EventTypes.CheckoutSessionCompleted:
                        var session = stripeEvent.Data.Object as Stripe.Checkout.Session;
                        if (session != null)
                        {
                            await HandleCheckoutCompleted(session);
                        }
                        break;

                    case EventTypes.InvoicePaid:
                        var invoice = stripeEvent.Data.Object as Invoice;
                        if (invoice != null)
                        {
                            await HandleInvoicePaid(invoice);
                        }
                        break;

                    case EventTypes.CustomerSubscriptionDeleted:
                        var subscription = stripeEvent.Data.Object as Subscription;
                        if (subscription != null)
                        {
                            await HandleSubscriptionCancelled(subscription);
                        }
                        break;
                }

                return Ok();
            }
            catch (StripeException)
            {
                return BadRequest();
            }
        }

        private async Task HandleCheckoutCompleted(Stripe.Checkout.Session session)
        {
            if (session.Metadata.TryGetValue("userId", out var userIdStr) &&
                int.TryParse(userIdStr, out int userId))
            {
                var user = await _context.Users.FindAsync(userId);
                if (user != null)
                {
                    user.IsVip = true;
                    user.VipActivatedAt = DateTime.UtcNow;
                    user.VipExpiresAt = DateTime.UtcNow.AddMonths(1);
                    user.StripeSubscriptionId = session.SubscriptionId;
                    await _context.SaveChangesAsync();

                    try
                    {
                        _messagePublisher.PublishEmail(new EmailMessage
                        {
                            To = user.Email,
                            Subject = "VIP Membership Activated!",
                            Body = $"<h2>Congratulations, {user.FirstName}!</h2><p>Your VIP membership has been activated and is valid until {user.VipExpiresAt:dd.MM.yyyy}.</p><p>Enjoy highlighted ads and priority listing!</p>"
                        });
                    }
                    catch { }
                }
            }
        }

        private async Task HandleInvoicePaid(Invoice invoice)
        {
            var subscriptionId = invoice.SubscriptionId;
            if (string.IsNullOrEmpty(subscriptionId)) return;

            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.StripeSubscriptionId == subscriptionId);

            if (user != null)
            {
                user.IsVip = true;
                user.VipExpiresAt = DateTime.UtcNow.AddMonths(1);
                await _context.SaveChangesAsync();
            }
        }

        private async Task HandleSubscriptionCancelled(Subscription subscription)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.StripeSubscriptionId == subscription.Id);

            if (user != null)
            {
                user.IsVip = false;
                user.StripeSubscriptionId = null;
                user.VipExpiresAt = null;
                await _context.SaveChangesAsync();
            }
        }

        [HttpGet("status/{userId}")]
        public async Task<IActionResult> GetSubscriptionStatus(int userId)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null || user.IsDeleted)
                return NotFound(new { message = "User not found." });

            return Ok(new
            {
                isVip = user.IsVip,
                vipActivatedAt = user.VipActivatedAt,
                vipExpiresAt = user.VipExpiresAt,
                hasSubscription = !string.IsNullOrEmpty(user.StripeSubscriptionId)
            });
        }
    }
}