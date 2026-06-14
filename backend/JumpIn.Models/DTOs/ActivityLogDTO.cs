namespace JumpIn.Models.DTOs
{
    public class ActivityLogDTO
    {
        public Guid Id { get; set; }
        public string ActivityType { get; set; }
        public string Description { get; set; }
        public Guid? EntityId { get; set; }
        public string? EntityType { get; set; }
        public string? IpAddress { get; set; }
        public DateTime CreatedAt { get; set; }
        public Guid UserId { get; set; }
        public string? UserName { get; set; }
    }
}
