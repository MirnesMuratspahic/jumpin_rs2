using JumpIn.Models.Enums;

namespace JumpIn.Services.Database
{
    public class Request : ISoftDeletable
    {
        public int Id { get; set; }
        public string RequestNumber { get; set; }

        public int SenderId { get; set; }
        public virtual User Sender { get; set; }

        public int ReceiverId { get; set; }
        public virtual User Receiver { get; set; }

        public int AdId { get; set; }
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
