using System.Text.Json.Serialization;

namespace JumpIn.Models.DTOs
{
    public class UserModel
    {
        public Guid Id { get; set; }

        // Server-side use only (token validation); never returned to clients.
        [JsonIgnore]
        public string? SecurityStamp { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string? Phone { get; set; }
        public string? ProfileImageUrl { get; set; }
        public DateTime RegistrationDate { get; set; }
        public DateTime? LastLogin { get; set; }
        public string Status { get; set; }
        public string? BlockReason { get; set; }
        public string Role { get; set; }
        public bool IsVip { get; set; }
        public DateTime? VipActivatedAt { get; set; }
        public DateTime? VipExpiresAt { get; set; }
        public bool VipCancelAtPeriodEnd { get; set; }
        public decimal AverageRating { get; set; }
        public int TotalReviews { get; set; }
        public int TotalAds { get; set; }
    }
}
