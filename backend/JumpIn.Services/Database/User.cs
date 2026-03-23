using JumpIn.Models.Enums;

namespace JumpIn.Services.Database
{
    public class User : ISoftDeletable
    {
        public int Id { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Username { get; set; }
        public string Email { get; set; }
        public string PasswordHash { get; set; }
        public string? Phone { get; set; }
        public string? ProfileImageUrl { get; set; }
        public DateTime RegistrationDate { get; set; }
        public DateTime? LastLogin { get; set; }
        public UserStatus Status { get; set; }
        public string? BlockReason { get; set; }
        public DateTime? BlockedAt { get; set; }
        public UserRole Role { get; set; }
        public bool IsVip { get; set; }
        public DateTime? VipActivatedAt { get; set; }
        public DateTime? VipExpiresAt { get; set; }
        public string? StripeCustomerId { get; set; }
        public string? StripeSubscriptionId { get; set; }

        // Soft delete
        public bool IsDeleted { get; set; }
        public DateTime? DeleteTime { get; set; }

        // Navigation
        public virtual ICollection<Ad> Ads { get; set; } = new List<Ad>();
        public virtual ICollection<Request> SentRequests { get; set; } = new List<Request>();
        public virtual ICollection<Request> ReceivedRequests { get; set; } = new List<Request>();
        public virtual ICollection<Review> ReviewsGiven { get; set; } = new List<Review>();
        public virtual ICollection<Review> ReviewsReceived { get; set; } = new List<Review>();
        public virtual ICollection<SupportMessage> SupportMessages { get; set; } = new List<SupportMessage>();
        public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();
        public virtual ICollection<Favorite> Favorites { get; set; } = new List<Favorite>();
        public virtual ICollection<UserPreference> UserPreferences { get; set; } = new List<UserPreference>();
        public virtual ICollection<ActivityLog> ActivityLogs { get; set; } = new List<ActivityLog>();
    }
}
