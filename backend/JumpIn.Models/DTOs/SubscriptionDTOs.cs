namespace JumpIn.Models.DTOs
{
    public class SubscriptionInitResult
    {
        public string SubscriptionId { get; set; } = "";
        public string? ClientSecret { get; set; }
        public string? PublishableKey { get; set; }
    }

    public class SubscriptionStatusResult
    {
        public bool IsVip { get; set; }
        public DateTime? VipActivatedAt { get; set; }
        public DateTime? VipExpiresAt { get; set; }
        public bool CancelAtPeriodEnd { get; set; }
        public bool HasSubscription { get; set; }
    }
}
