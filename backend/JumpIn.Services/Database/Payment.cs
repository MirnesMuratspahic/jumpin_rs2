using JumpIn.Models.Enums;

namespace JumpIn.Services.Database
{
    public class Payment
    {
        public Guid Id { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "BAM";
        public PaymentType PaymentType { get; set; }
        public PaymentStatus Status { get; set; }
        public string? StripePaymentId { get; set; }
        public string? Description { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? CompletedAt { get; set; }

        // Foreign key
        public Guid UserId { get; set; }
        public virtual User User { get; set; }
    }
}
