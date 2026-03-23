using JumpIn.Models.Enums;

namespace JumpIn.Models.Requests
{
    public class PaymentInsertRequest
    {
        public int UserId { get; set; }
        public decimal Amount { get; set; }
        public string? Currency { get; set; }
        public PaymentType PaymentType { get; set; }
        public string? StripePaymentId { get; set; }
        public string? Description { get; set; }
    }
}
