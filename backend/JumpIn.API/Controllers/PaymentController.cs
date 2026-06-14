using System.Security.Claims;
using JumpIn.Models.Constants;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentService _paymentService;
        private readonly ISubscriptionService _subscriptionService;

        public PaymentController(IPaymentService paymentService, ISubscriptionService subscriptionService)
        {
            _paymentService = paymentService;
            _subscriptionService = subscriptionService;
        }

        private Guid? CurrentUserId =>
            Guid.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : null;
        private bool IsAdmin => User.FindFirst(ClaimTypes.Role)?.Value == RoleNames.Admin;
        private bool OwnsOrAdmin(Guid ownerId) => IsAdmin || CurrentUserId == ownerId;

        private IActionResult Forbidden(string message) =>
            StatusCode(403, new { errors = new { Forbidden = new[] { message } } });

        [HttpGet("history")]
        public async Task<IActionResult> GetPaymentHistory([FromQuery] PaymentSearchObject search)
        {
            // A user may only see their own payment history; admins see all.
            if (!IsAdmin && CurrentUserId != null) search.UserId = CurrentUserId.Value;
            return Ok(await _paymentService.GetPagedAsync(search));
        }

        [HttpGet("history/{id}")]
        public IActionResult GetPaymentById(Guid id)
        {
            var payment = _paymentService.GetById(id);
            if (!OwnsOrAdmin(payment.UserId))
                return Forbidden("You are not allowed to view this payment.");
            return Ok(payment);
        }

        [HttpPost("create-checkout-session/{userId}")]
        public async Task<IActionResult> CreateCheckoutSession(Guid userId)
        {
            if (!OwnsOrAdmin(userId))
                return Forbidden("You can only start checkout for your own account.");

            var successUrl = $"{Request.Scheme}://{Request.Host}/api/Payment/success?session_id={{CHECKOUT_SESSION_ID}}";
            var cancelUrl = $"{Request.Scheme}://{Request.Host}/api/Payment/cancel";
            var url = await _subscriptionService.CreateCheckoutSessionAsync(userId, successUrl, cancelUrl);
            return Ok(new { url });
        }

        [HttpPost("create-subscription/{userId}")]
        public async Task<IActionResult> CreateSubscription(Guid userId)
        {
            if (!OwnsOrAdmin(userId))
                return Forbidden("You can only subscribe your own account.");

            var result = await _subscriptionService.CreateSubscriptionAsync(userId);
            return Ok(new
            {
                subscriptionId = result.SubscriptionId,
                clientSecret = result.ClientSecret,
                publishableKey = result.PublishableKey
            });
        }

        [HttpPost("confirm-subscription/{userId}")]
        public async Task<IActionResult> ConfirmSubscription(Guid userId)
        {
            if (!OwnsOrAdmin(userId))
                return Forbidden("You can only confirm your own subscription.");

            var status = await _subscriptionService.ConfirmSubscriptionAsync(userId);
            return Ok(new { isVip = status.IsVip, vipExpiresAt = status.VipExpiresAt });
        }

        [HttpPost("cancel-subscription/{userId}")]
        public async Task<IActionResult> CancelSubscription(Guid userId)
        {
            if (!OwnsOrAdmin(userId))
                return Forbidden("You can only cancel your own subscription.");

            var status = await _subscriptionService.CancelSubscriptionAsync(userId);
            return Ok(new { vipExpiresAt = status.VipExpiresAt, cancelAtPeriodEnd = status.CancelAtPeriodEnd });
        }

        [HttpGet("status/{userId}")]
        public async Task<IActionResult> GetSubscriptionStatus(Guid userId)
        {
            if (!OwnsOrAdmin(userId))
                return Forbidden("You can only view your own subscription status.");

            var status = await _subscriptionService.GetStatusAsync(userId);
            return Ok(new
            {
                isVip = status.IsVip,
                vipActivatedAt = status.VipActivatedAt,
                vipExpiresAt = status.VipExpiresAt,
                cancelAtPeriodEnd = status.CancelAtPeriodEnd,
                hasSubscription = status.HasSubscription
            });
        }

        [AllowAnonymous]
        [HttpGet("success")]
        public async Task<IActionResult> Success([FromQuery] string session_id)
        {
            await _subscriptionService.HandleSuccessAsync(session_id);
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
            var signature = Request.Headers["Stripe-Signature"];

            var result = await _subscriptionService.HandleWebhookAsync(json, signature);
            return result switch
            {
                WebhookResult.Handled => Ok(),
                WebhookResult.NotConfigured => StatusCode(503, new { message = "Webhook is not configured." }),
                _ => BadRequest()
            };
        }
    }
}
