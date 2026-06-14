namespace JumpIn.Models.DTOs
{
    public class SupportMessageDTO
    {
        public Guid Id { get; set; }
        public string Subject { get; set; }
        public string Message { get; set; }
        public string? AdminResponse { get; set; }
        public string Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? RespondedAt { get; set; }

        public Guid UserId { get; set; }
        public string? UserUsername { get; set; }
        public string? UserEmail { get; set; }
    }
}
