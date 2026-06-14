namespace JumpIn.Services.Database
{
    public class Notification
    {
        public Guid Id { get; set; }
        public string Title { get; set; }
        public string Message { get; set; }
        public string Type { get; set; }
        public bool IsRead { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? ReadAt { get; set; }

        // Recipient
        public Guid UserId { get; set; }
        public virtual User User { get; set; }
    }
}
