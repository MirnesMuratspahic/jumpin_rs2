namespace JumpIn.Models.SearchObjects
{
    public class UserPreferenceSearchObject : BaseSearchObject
    {
        public Guid? UserId { get; set; }
        public string? PreferredAdType { get; set; }
    }
}
