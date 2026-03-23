namespace JumpIn.Models.SearchObjects
{
    public class AdSearchObject : BaseSearchObject
    {
        public string? SearchTerm { get; set; }
        public string? AdType { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public string? Location { get; set; }
        public int? UserId { get; set; }
        public bool? IsActive { get; set; }
        public bool? IsVipOwner { get; set; }
    }
}
