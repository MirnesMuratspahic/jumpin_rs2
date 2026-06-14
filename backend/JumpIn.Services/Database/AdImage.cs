namespace JumpIn.Services.Database
{
    public class AdImage
    {
        public Guid Id { get; set; }
        public string ImageUrl { get; set; }
        public bool IsMainImage { get; set; }
        public int DisplayOrder { get; set; }
        public DateTime CreatedAt { get; set; }

        // Foreign key
        public Guid AdId { get; set; }
        public virtual Ad Ad { get; set; }
    }
}
