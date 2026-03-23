namespace JumpIn.Models.SearchObjects
{
    public class ActivityLogSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public string? ActivityType { get; set; }
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
    }
}
