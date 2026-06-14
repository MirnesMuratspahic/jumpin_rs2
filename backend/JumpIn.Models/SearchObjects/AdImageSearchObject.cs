namespace JumpIn.Models.SearchObjects
{
    public class AdImageSearchObject : BaseSearchObject
    {
        public Guid? AdId { get; set; }
        public bool? IsMainImage { get; set; }
    }
}
