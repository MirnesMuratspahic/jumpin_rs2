namespace JumpIn.Models.SearchObjects
{
    public class SupportSearchObject : BaseSearchObject
    {
        public Guid? UserId { get; set; }
        public string? Status { get; set; }
        public string? SearchTerm { get; set; }
    }
}
