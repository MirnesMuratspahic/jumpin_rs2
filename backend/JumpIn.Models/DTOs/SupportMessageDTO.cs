namespace JumpIn.Models.DTOs
{
    public class SupportMessageDTO
    {
        public int Id { get; set; }
        public string Subject { get; set; }
        public string Message { get; set; }
        public string? Response { get; set; }
        public string Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? RespondedAt { get; set; }

        public int UserId { get; set; }
        public string? UserName { get; set; }
        public string? UserEmail { get; set; }
    }
}
