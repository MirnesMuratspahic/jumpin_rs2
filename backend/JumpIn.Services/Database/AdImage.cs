namespace JumpIn.Services.Database
{
    public class AdImage
    {
        public int Id { get; set; }
        public string ImageUrl { get; set; }
        public bool IsMainImage { get; set; }
        public int DisplayOrder { get; set; }
        public DateTime CreatedAt { get; set; }

        // Foreign key
        public int AdId { get; set; }
        public virtual Ad Ad { get; set; }
    }
}
