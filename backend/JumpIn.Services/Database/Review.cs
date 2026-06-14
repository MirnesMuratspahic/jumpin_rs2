using System.ComponentModel.DataAnnotations.Schema;

namespace JumpIn.Services.Database
{
    public class Review
    {
        public Guid Id { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }

        public Guid ReviewerId { get; set; }
        public virtual User Reviewer { get; set; }

        [Column("ReviewerEmail")]
        public string? ReviewerEmail { get; set; }

        public Guid ReviewedUserId { get; set; }
        public virtual User ReviewedUser { get; set; }

        [Column("ReviewedUserEmail")]
        public string? ReviewedUserEmail { get; set; }

        public Guid? AdId { get; set; }
        public virtual Ad? Ad { get; set; }
    }
}
