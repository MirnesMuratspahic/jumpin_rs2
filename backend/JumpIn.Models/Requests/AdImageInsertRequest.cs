namespace JumpIn.Models.Requests
{
    public class AdImageInsertRequest
    {
        public int AdId { get; set; }
        public string ImageUrl { get; set; }
        public bool IsMainImage { get; set; }
        public int DisplayOrder { get; set; }
    }
}
