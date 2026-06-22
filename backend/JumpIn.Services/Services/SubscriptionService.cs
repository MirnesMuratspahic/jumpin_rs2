using JumpIn.Models.DTOs;
using JumpIn.Models.Enums;
using JumpIn.Models.Exceptions;
using JumpIn.Models.Messages;
using JumpIn.Services.Database;
using JumpIn.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Stripe;
using Stripe.Checkout;

namespace JumpIn.Services.Services
{
    /// Owns all Stripe subscription orchestration and the related VIP/user state.
    /// Keeps the controller free of DbContext and the Stripe SDK.
    public class SubscriptionService : ISubscriptionService
    {
        private readonly JumpInDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly IMessagePublisher _messagePublisher;
        private readonly INotificationService _notificationService;
        private readonly ILogger<SubscriptionService> _logger;

        public SubscriptionService(
            JumpInDbContext context,
            IConfiguration configuration,
            IMessagePublisher messagePublisher,
            INotificationService notificationService,
            ILogger<SubscriptionService> logger)
        {
            _context = context;
            _configuration = configuration;
            _messagePublisher = messagePublisher;
            _notificationService = notificationService;
            _logger = logger;
            StripeConfiguration.ApiKey = _configuration["Stripe:SecretKey"];
        }

        private string Currency => _configuration["Stripe:Currency"] ?? "bam";
        private long PriceAmount => long.Parse(_configuration["Stripe:VipPriceAmountInCents"] ?? "2000");

        public async Task<string?> CreateCheckoutSessionAsync(Guid userId, string successUrl, string cancelUrl)
        {
            var user = await RequireActiveUserAsync(userId);
            if (user.IsVip)
                throw new UserException("User already has an active VIP subscription.");

            await EnsureNoPendingVipPaymentAsync(user.Id);

            var customerId = await GetOrCreateCustomerAsync(user);

            var session = await new SessionService().CreateAsync(new SessionCreateOptions
            {
                Customer = customerId,
                PaymentMethodTypes = new List<string> { "card" },
                LineItems = new List<SessionLineItemOptions>
                {
                    new SessionLineItemOptions
                    {
                        PriceData = new SessionLineItemPriceDataOptions
                        {
                            Currency = Currency,
                            UnitAmount = PriceAmount,
                            Recurring = new SessionLineItemPriceDataRecurringOptions { Interval = "month" },
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
                SuccessUrl = successUrl,
                CancelUrl = cancelUrl,
                Metadata = new Dictionary<string, string> { { "userId", user.Id.ToString() } }
            });

            await RecordVipPaymentAsync(user, session.Id, PaymentStatus.Pending);

            return session.Url;
        }

        public async Task<SubscriptionInitResult> CreateSubscriptionAsync(Guid userId)
        {
            var user = await RequireActiveUserAsync(userId);
            if (user.IsVip)
                throw new UserException("User already has an active VIP subscription.");

            await EnsureNoPendingVipPaymentAsync(user.Id);

            var customerId = await GetOrCreateCustomerAsync(user);

            // Subscription price_data requires a product id (no inline product data).
            var product = await new ProductService().CreateAsync(new ProductCreateOptions
            {
                Name = "JumpIn VIP Membership"
            });

            var subscription = await new Stripe.SubscriptionService().CreateAsync(new SubscriptionCreateOptions
            {
                Customer = customerId,
                Items = new List<SubscriptionItemOptions>
                {
                    new SubscriptionItemOptions
                    {
                        PriceData = new SubscriptionItemPriceDataOptions
                        {
                            Currency = Currency,
                            UnitAmount = PriceAmount,
                            Product = product.Id,
                            Recurring = new SubscriptionItemPriceDataRecurringOptions { Interval = "month" }
                        }
                    }
                },
                PaymentBehavior = "default_incomplete",
                PaymentSettings = new SubscriptionPaymentSettingsOptions
                {
                    SaveDefaultPaymentMethod = "on_subscription"
                },
                Expand = new List<string> { "latest_invoice.payment_intent" },
                Metadata = new Dictionary<string, string> { { "userId", user.Id.ToString() } }
            });

            user.StripeSubscriptionId = subscription.Id;
            await _context.SaveChangesAsync();

            // Record the financial event as a pending Payment; it is completed once
            // the subscription is confirmed/paid (server-side).
            await RecordVipPaymentAsync(user, subscription.Id, PaymentStatus.Pending);

            var clientSecret = subscription.LatestInvoice?.PaymentIntent?.ClientSecret;
            if (string.IsNullOrEmpty(clientSecret))
                throw new UserException("Could not initialize payment.");

            return new SubscriptionInitResult
            {
                SubscriptionId = subscription.Id,
                ClientSecret = clientSecret,
                PublishableKey = _configuration["Stripe:PublishableKey"]
            };
        }

        public async Task<SubscriptionStatusResult> ConfirmSubscriptionAsync(Guid userId)
        {
            var user = await RequireActiveUserAsync(userId);
            if (string.IsNullOrEmpty(user.StripeSubscriptionId))
                throw new UserException("No subscription to confirm.");

            var sub = await new Stripe.SubscriptionService().GetAsync(user.StripeSubscriptionId);
            if (sub.Status != "active" && sub.Status != "trialing")
                throw new UserException($"Subscription is not active (status: {sub.Status}).");

            user.IsVip = true;
            user.VipActivatedAt = DateTime.UtcNow;
            user.VipExpiresAt = DateTime.UtcNow.AddMonths(1);
            user.VipCancelAtPeriodEnd = false;
            await _context.SaveChangesAsync();

            await RecordVipPaymentAsync(user, user.StripeSubscriptionId, PaymentStatus.Completed);

            await _notificationService.CreateAsync(
                user.Id,
                "VIP activated",
                $"Your VIP membership is active until {user.VipExpiresAt:dd.MM.yyyy}. Enjoy highlighted ads and priority listing!",
                "VIP_ACTIVATED");

            return ToStatus(user);
        }

        public async Task<SubscriptionStatusResult> CancelSubscriptionAsync(Guid userId)
        {
            var user = await RequireActiveUserAsync(userId);
            if (string.IsNullOrEmpty(user.StripeSubscriptionId) || !user.IsVip)
                throw new UserException("No active subscription to cancel.");

            await new Stripe.SubscriptionService().UpdateAsync(user.StripeSubscriptionId,
                new SubscriptionUpdateOptions { CancelAtPeriodEnd = true });

            user.VipCancelAtPeriodEnd = true;
            await _context.SaveChangesAsync();

            await _notificationService.CreateAsync(
                user.Id,
                "Subscription cancelled",
                $"Your VIP will remain active until {user.VipExpiresAt:dd.MM.yyyy} and will not renew after that.",
                "VIP_CANCELLED");

            return ToStatus(user);
        }

        public async Task<SubscriptionStatusResult> GetStatusAsync(Guid userId)
        {
            var user = await RequireActiveUserAsync(userId);
            return ToStatus(user);
        }

        public async Task HandleSuccessAsync(string sessionId)
        {
            var session = await new SessionService().GetAsync(sessionId);
            if (session.PaymentStatus == "paid" || session.Status == "complete")
            {
                if (session.Metadata.TryGetValue("userId", out var userIdStr) &&
                    Guid.TryParse(userIdStr, out var userId))
                {
                    var user = await _context.Users.FindAsync(userId);
                    if (user != null)
                        await ActivateVipAsync(user, session.SubscriptionId);
                }
            }
        }

        public async Task<WebhookResult> HandleWebhookAsync(string json, string? signature)
        {
            var secret = _configuration["Stripe:WebhookSecret"];
            if (string.IsNullOrEmpty(secret))
                return WebhookResult.NotConfigured;

            Event stripeEvent;
            try
            {
                stripeEvent = EventUtility.ConstructEvent(json, signature, secret);
            }
            catch (StripeException)
            {
                return WebhookResult.Invalid;
            }

            switch (stripeEvent.Type)
            {
                case EventTypes.CheckoutSessionCompleted:
                    if (stripeEvent.Data.Object is Session session)
                        await HandleCheckoutCompleted(session);
                    break;

                case EventTypes.InvoicePaid:
                    if (stripeEvent.Data.Object is Invoice invoice)
                        await HandleInvoicePaid(invoice);
                    break;

                case EventTypes.InvoicePaymentFailed:
                    if (stripeEvent.Data.Object is Invoice failedInvoice)
                        await HandleInvoicePaymentFailed(failedInvoice);
                    break;

                case EventTypes.CustomerSubscriptionDeleted:
                    if (stripeEvent.Data.Object is Subscription subscription)
                        await HandleSubscriptionCancelled(subscription);
                    break;
            }

            return WebhookResult.Handled;
        }

        // ---- private helpers ----

        private async Task<User> RequireActiveUserAsync(Guid userId)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null || user.IsDeleted)
                throw new UserException("User not found.");
            return user;
        }

        // A user must not have more than one open VIP payment attempt at a time.
        private async Task EnsureNoPendingVipPaymentAsync(Guid userId)
        {
            var hasPending = await _context.Payments.AnyAsync(p =>
                p.UserId == userId &&
                p.PaymentType == PaymentType.VipSubscription &&
                p.Status == PaymentStatus.Pending);

            if (hasPending)
                throw new UserException("You already have a pending VIP payment. Complete or cancel it before starting a new one.");
        }

        // Creates or updates the Payment row that mirrors the real Stripe charge so
        // the Payment history reflects actual financial events (not a separate CRUD).
        private async Task RecordVipPaymentAsync(User user, string? stripeId, PaymentStatus status)
        {
            // Advance the user's currently OPEN (pending) payment if one exists — this
            // is the initial subscription attempt being confirmed or failing. We never
            // mutate an already-finalized (completed/failed) row, so monthly renewals
            // and standalone failures each create their own new Payment record.
            var pending = await _context.Payments.FirstOrDefaultAsync(p =>
                p.UserId == user.Id &&
                p.PaymentType == PaymentType.VipSubscription &&
                p.Status == PaymentStatus.Pending);

            if (pending != null)
            {
                pending.Status = status;
                if (!string.IsNullOrEmpty(stripeId)) pending.StripePaymentId = stripeId;
                if (status == PaymentStatus.Completed) pending.CompletedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
                return;
            }

            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                Amount = PriceAmount / 100m,
                Currency = Currency.ToUpper(),
                PaymentType = PaymentType.VipSubscription,
                Status = status,
                StripePaymentId = stripeId,
                Description = "JumpIn VIP Membership (monthly)",
                CreatedAt = DateTime.UtcNow,
                CompletedAt = status == PaymentStatus.Completed ? DateTime.UtcNow : null
            };
            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();
        }

        private static SubscriptionStatusResult ToStatus(User user) => new()
        {
            IsVip = user.IsVip,
            VipActivatedAt = user.VipActivatedAt,
            VipExpiresAt = user.VipExpiresAt,
            CancelAtPeriodEnd = user.VipCancelAtPeriodEnd,
            HasSubscription = !string.IsNullOrEmpty(user.StripeSubscriptionId)
        };

        private async Task<string> GetOrCreateCustomerAsync(User user)
        {
            if (!string.IsNullOrEmpty(user.StripeCustomerId))
                return user.StripeCustomerId;

            var customer = await new CustomerService().CreateAsync(new CustomerCreateOptions
            {
                Email = user.Email,
                Name = $"{user.FirstName} {user.LastName}",
                Metadata = new Dictionary<string, string> { { "userId", user.Id.ToString() } }
            });
            user.StripeCustomerId = customer.Id;
            await _context.SaveChangesAsync();
            return customer.Id;
        }

        private async Task HandleCheckoutCompleted(Session session)
        {
            if (session.Metadata.TryGetValue("userId", out var userIdStr) &&
                Guid.TryParse(userIdStr, out var userId))
            {
                var user = await _context.Users.FindAsync(userId);
                if (user != null)
                    await ActivateVipAsync(user, session.SubscriptionId);
            }
        }

        private async Task HandleInvoicePaid(Invoice invoice)
        {
            var subscriptionId = invoice.SubscriptionId;
            if (string.IsNullOrEmpty(subscriptionId)) return;

            var user = await _context.Users.FirstOrDefaultAsync(u => u.StripeSubscriptionId == subscriptionId);
            if (user != null)
            {
                user.IsVip = true;
                user.VipExpiresAt = DateTime.UtcNow.AddMonths(1);
                await _context.SaveChangesAsync();

                // Each paid invoice (initial + monthly renewals) is a completed payment.
                await RecordVipPaymentAsync(user, subscriptionId, PaymentStatus.Completed);
            }
        }

        private async Task HandleInvoicePaymentFailed(Invoice invoice)
        {
            var subscriptionId = invoice.SubscriptionId;
            if (string.IsNullOrEmpty(subscriptionId)) return;

            var user = await _context.Users.FirstOrDefaultAsync(u => u.StripeSubscriptionId == subscriptionId);
            if (user == null) return;

            // Reflect the failed charge in the Payment history and let the user know.
            await RecordVipPaymentAsync(user, subscriptionId, PaymentStatus.Failed);

            await _notificationService.CreateAsync(
                user.Id,
                "Payment failed",
                "Your VIP subscription payment could not be processed. Please update your payment method to keep VIP active.",
                "VIP_PAYMENT_FAILED");
        }

        private async Task HandleSubscriptionCancelled(Subscription subscription)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.StripeSubscriptionId == subscription.Id);
            if (user != null)
            {
                user.IsVip = false;
                user.StripeSubscriptionId = null;
                user.VipExpiresAt = null;
                user.VipCancelAtPeriodEnd = false;
                await _context.SaveChangesAsync();
            }
        }

        // Idempotent: a repeated callback for an already-activated subscription
        // must not re-activate or re-notify.
        private async Task ActivateVipAsync(User user, string? subscriptionId)
        {
            if (user.IsVip && user.StripeSubscriptionId == subscriptionId)
                return;

            user.IsVip = true;
            user.VipActivatedAt = DateTime.UtcNow;
            user.VipExpiresAt = DateTime.UtcNow.AddMonths(1);
            user.VipCancelAtPeriodEnd = false;
            user.StripeSubscriptionId = subscriptionId;
            await _context.SaveChangesAsync();

            await RecordVipPaymentAsync(user, subscriptionId, PaymentStatus.Completed);

            await _notificationService.CreateAsync(
                user.Id,
                "VIP activated",
                $"Your VIP membership is active until {user.VipExpiresAt:dd.MM.yyyy}. Enjoy highlighted ads and priority listing!",
                "VIP_ACTIVATED");

            try
            {
                await _messagePublisher.PublishEmailAsync(new EmailMessage
                {
                    To = user.Email,
                    Subject = "VIP Membership Activated!",
                    Body = $"<h2>Congratulations, {user.FirstName}!</h2><p>Your VIP membership has been activated and is valid until {user.VipExpiresAt:dd.MM.yyyy}.</p><p>Enjoy highlighted ads and priority listing!</p>"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish VIP activation email for user {UserId}.", user.Id);
            }
        }
    }
}
