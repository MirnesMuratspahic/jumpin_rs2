namespace JumpIn.Models.Requests
{
    public class RequestInsertRequest
    {
        public int SenderId { get; set; }
        public int AdId { get; set; }
        public string? Message { get; set; }
    }
}
