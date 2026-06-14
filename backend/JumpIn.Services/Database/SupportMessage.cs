using JumpIn.Models.Enums;

namespace JumpIn.Services.Database
{
    public class SupportMessage
    {
        public Guid Id { get; set; }
        public string Subject { get; set; }
        public string Message { get; set; }
        public string? Response { get; set; }
        public SupportStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? RespondedAt { get; set; }

        public Guid UserId { get; set; }
        public virtual User User { get; set; }
        public virtual List<SupportChat> ChatMessages { get; set; } = new();
    }
}
