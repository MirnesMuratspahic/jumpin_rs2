namespace JumpIn.Models.Requests
{
    public class SupportInsertRequest
    {
        public string Subject { get; set; }
        public string Message { get; set; }
        public Guid UserId { get; set; }
    }
}
