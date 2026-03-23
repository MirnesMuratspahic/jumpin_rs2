namespace JumpIn.Models.DTOs
{
    public class ActivityLogDTO
    {
        public int Id { get; set; }
        public string ActivityType { get; set; }
        public string Description { get; set; }
        public int? EntityId { get; set; }
        public string? EntityType { get; set; }
        public string? IpAddress { get; set; }
        public DateTime CreatedAt { get; set; }
        public int UserId { get; set; }
        public string? UserName { get; set; }
    }
}
