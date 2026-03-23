namespace JumpIn.Models.SearchObjects
{
    public class SupportSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public string? Status { get; set; }
        public string? SearchTerm { get; set; }
    }
}
