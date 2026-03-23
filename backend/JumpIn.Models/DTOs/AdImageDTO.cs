namespace JumpIn.Models.DTOs
{
    public class AdImageDTO
    {
        public int Id { get; set; }
        public string ImageUrl { get; set; }
        public bool IsMainImage { get; set; }
        public int DisplayOrder { get; set; }
        public DateTime CreatedAt { get; set; }
        public int AdId { get; set; }
    }
}
