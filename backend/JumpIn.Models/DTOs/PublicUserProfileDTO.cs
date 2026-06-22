namespace JumpIn.Models.DTOs
{
    /// <summary>
    /// Minimal, public-safe view of a user shown to OTHER users (e.g. an ad owner's
    /// profile). Deliberately omits private data — email, phone, role, status,
    /// block reason, security stamp — which only the owner or an admin may see.
    /// </summary>
    public class PublicUserProfileDTO
    {
        public Guid Id { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string? ProfileImageUrl { get; set; }
        public DateTime RegistrationDate { get; set; }
        public bool IsVip { get; set; }
        public decimal AverageRating { get; set; }
        public int TotalReviews { get; set; }
        public int TotalAds { get; set; }
    }
}
