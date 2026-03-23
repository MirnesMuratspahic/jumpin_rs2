namespace JumpIn.Models.DTOs
{
    public class ReviewDTO
    {
        public int Id { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }

        public int ReviewerId { get; set; }
        public string? ReviewerName { get; set; }
        public string? ReviewerProfileImage { get; set; }

        public int ReviewedUserId { get; set; }
        public string? ReviewedUserName { get; set; }

        public int? AdId { get; set; }
        public string? AdTitle { get; set; }
    }
}
