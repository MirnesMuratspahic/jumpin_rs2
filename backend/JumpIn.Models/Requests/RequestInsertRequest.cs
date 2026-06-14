namespace JumpIn.Models.Requests
{
    public class RequestInsertRequest
    {
        public Guid SenderId { get; set; }
        public Guid AdId { get; set; }
        public string? Message { get; set; }
    }
}
