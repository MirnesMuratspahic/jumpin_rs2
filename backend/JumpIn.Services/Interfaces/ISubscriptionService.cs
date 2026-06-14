using JumpIn.Models.DTOs;

namespace JumpIn.Services.Interfaces
{
    public enum WebhookResult { Handled, NotConfigured, Invalid }

    public interface ISubscriptionService
    {
        Task<string?> CreateCheckoutSessionAsync(Guid userId, string successUrl, string cancelUrl);
        Task<SubscriptionInitResult> CreateSubscriptionAsync(Guid userId);
        Task<SubscriptionStatusResult> ConfirmSubscriptionAsync(Guid userId);
        Task<SubscriptionStatusResult> CancelSubscriptionAsync(Guid userId);
        Task<SubscriptionStatusResult> GetStatusAsync(Guid userId);
        Task HandleSuccessAsync(string sessionId);
        Task<WebhookResult> HandleWebhookAsync(string json, string? signature);
    }
}
