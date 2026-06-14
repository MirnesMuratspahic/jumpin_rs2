namespace JumpIn.Models.Messages
{
    public class NotificationMessage
    {
        public Guid UserId { get; set; }
        public string Title { get; set; }
        public string Body { get; set; }
        public string Type { get; set; }
    }
}
