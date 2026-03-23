namespace JumpIn.Models.Requests
{
    public class ReviewInsertRequest
    {
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public int ReviewerId { get; set; }
        public int ReviewedUserId { get; set; }
        public int? AdId { get; set; }
    }
}
