using JumpIn.Models.Enums;

namespace JumpIn.Services.Database
{
    public class SupportChat
    {
        public Guid Id { get; set; }
        public Guid SupportMessageId { get; set; }
        public string Message { get; set; }
        public bool IsAdminMessage { get; set; }
        public DateTime CreatedAt { get; set; }

        public SupportMessage SupportMessage { get; set; }
    }
}
