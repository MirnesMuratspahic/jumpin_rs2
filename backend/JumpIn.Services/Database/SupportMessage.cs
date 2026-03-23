using JumpIn.Models.Enums;

namespace JumpIn.Services.Database
{
    public class SupportMessage
    {
        public int Id { get; set; }
        public string Subject { get; set; }
        public string Message { get; set; }
        public string? Response { get; set; }
        public SupportStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? RespondedAt { get; set; }

        public int UserId { get; set; }
        public virtual User User { get; set; }
    }
}
