namespace JumpIn.Services.Database
{
    public class Review
    {
        public int Id { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }

        public int ReviewerId { get; set; }
        public virtual User Reviewer { get; set; }

        public int ReviewedUserId { get; set; }
        public virtual User ReviewedUser { get; set; }

        public int? AdId { get; set; }
        public virtual Ad? Ad { get; set; }
    }
}
