namespace JumpIn.Models.DTOs
{
    public class PaymentDTO
    {
        public Guid Id { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; }
        public string PaymentType { get; set; }
        public string Status { get; set; }
        public string? StripePaymentId { get; set; }
        public string? Description { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
        public Guid UserId { get; set; }
        public string? UserName { get; set; }
    }
}
