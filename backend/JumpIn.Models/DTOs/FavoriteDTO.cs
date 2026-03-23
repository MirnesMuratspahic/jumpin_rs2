namespace JumpIn.Models.DTOs
{
    public class FavoriteDTO
    {
        public int Id { get; set; }
        public DateTime CreatedAt { get; set; }
        public int UserId { get; set; }
        public string? UserName { get; set; }
        public int AdId { get; set; }
        public string? AdTitle { get; set; }
        public string? AdType { get; set; }
        public string? AdImageUrl { get; set; }
    }
}
