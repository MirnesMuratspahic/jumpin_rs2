namespace JumpIn.Models.SearchObjects
{
    public class ReviewSearchObject : BaseSearchObject
    {
        public Guid? ReviewerId { get; set; }
        public Guid? ReviewedUserId { get; set; }
        public int? MinRating { get; set; }
        public int? MaxRating { get; set; }
        public string? SearchTerm { get; set; }
    }
}
