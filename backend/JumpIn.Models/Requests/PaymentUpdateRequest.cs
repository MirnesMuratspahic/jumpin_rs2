using JumpIn.Models.Enums;

namespace JumpIn.Models.Requests
{
    public class PaymentUpdateRequest
    {
        public PaymentStatus? Status { get; set; }
        public string? Description { get; set; }
    }
}
