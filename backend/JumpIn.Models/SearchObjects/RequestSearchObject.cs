namespace JumpIn.Models.SearchObjects
{
    public class RequestSearchObject : BaseSearchObject
    {
        public Guid? SenderId { get; set; }
        public Guid? ReceiverId { get; set; }
        public Guid? AdId { get; set; }
        public string? Status { get; set; }
        public string? AdType { get; set; }
    }
}
