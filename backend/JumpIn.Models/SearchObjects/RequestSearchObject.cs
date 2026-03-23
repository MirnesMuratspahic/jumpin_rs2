namespace JumpIn.Models.SearchObjects
{
    public class RequestSearchObject : BaseSearchObject
    {
        public int? SenderId { get; set; }
        public int? ReceiverId { get; set; }
        public int? AdId { get; set; }
        public string? Status { get; set; }
        public string? AdType { get; set; }
    }
}
