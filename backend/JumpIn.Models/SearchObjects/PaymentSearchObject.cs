namespace JumpIn.Models.SearchObjects
{
    public class PaymentSearchObject : BaseSearchObject
    {
        public Guid? UserId { get; set; }
        public string? Status { get; set; }
        public string? PaymentType { get; set; }
        public decimal? MinAmount { get; set; }
        public decimal? MaxAmount { get; set; }
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
    }
}
