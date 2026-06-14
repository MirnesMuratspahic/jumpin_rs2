namespace JumpIn.Models.Requests
{
    public class ReviewInsertRequest
    {
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public Guid ReviewerId { get; set; }
        public Guid ReviewedUserId { get; set; }
        public Guid? AdId { get; set; }
    }
}
