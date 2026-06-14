using JumpIn.Models.Enums;

namespace JumpIn.Services.Database
{
    public class Request : ISoftDeletable
    {
        public Guid Id { get; set; }
        public string RequestNumber { get; set; }

        public Guid SenderId { get; set; }
        public virtual User Sender { get; set; }
        public string? SenderEmail { get; set; }

        public Guid ReceiverId { get; set; }
        public virtual User Receiver { get; set; }
        public string? ReceiverEmail { get; set; }

        public Guid AdId { get; set; }
        public virtual Ad Ad { get; set; }

        public RequestStatus Status { get; set; }
        public string? Message { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? RespondedAt { get; set; }

        // Soft delete
        public bool IsDeleted { get; set; }
        public DateTime? DeleteTime { get; set; }
    }
}
