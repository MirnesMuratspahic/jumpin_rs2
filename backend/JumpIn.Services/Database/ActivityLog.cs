using JumpIn.Models.Enums;

namespace JumpIn.Services.Database
{
    public class ActivityLog
    {
        public int Id { get; set; }
        public ActivityType ActivityType { get; set; }
        public string Description { get; set; }
        public int? EntityId { get; set; }
        public string? EntityType { get; set; }
        public string? IpAddress { get; set; }
        public DateTime CreatedAt { get; set; }

        // Foreign key
        public int UserId { get; set; }
        public virtual User User { get; set; }
    }
}
