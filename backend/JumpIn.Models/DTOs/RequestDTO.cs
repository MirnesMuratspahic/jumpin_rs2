namespace JumpIn.Models.DTOs
{
    public class RequestDTO
    {
        public int Id { get; set; }
        public string RequestNumber { get; set; }

        public int SenderId { get; set; }
        public string? SenderName { get; set; }
        public string? SenderEmail { get; set; }
        public string? SenderProfileImage { get; set; }

        public int ReceiverId { get; set; }
        public string? ReceiverName { get; set; }

        public int AdId { get; set; }
        public string? AdTitle { get; set; }
        public string? AdType { get; set; }

        public string Status { get; set; }
        public string? Message { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? RespondedAt { get; set; }
    }
}
