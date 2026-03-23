namespace JumpIn.Models.SearchObjects
{
    public class ReviewSearchObject : BaseSearchObject
    {
        public int? ReviewerId { get; set; }
        public int? ReviewedUserId { get; set; }
        public int? MinRating { get; set; }
        public int? MaxRating { get; set; }
        public string? SearchTerm { get; set; }
    }
}
