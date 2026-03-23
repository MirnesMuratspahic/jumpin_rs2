namespace JumpIn.Models.SearchObjects
{
    public class UserPreferenceSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public string? PreferredAdType { get; set; }
    }
}
