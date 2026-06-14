namespace JumpIn.Models.SearchObjects
{
    public class NotificationSearchObject : BaseSearchObject
    {
        public Guid? UserId { get; set; }
        public bool? IsRead { get; set; }
    }
}
