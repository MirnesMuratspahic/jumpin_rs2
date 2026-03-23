using JumpIn.Models.Enums;

namespace JumpIn.Services.Database
{
    public class UserPreference
    {
        public int Id { get; set; }
        public AdType? PreferredAdType { get; set; }
        public string? PreferredLocation { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public string? PreferredCarBrand { get; set; }
        public string? PreferredFuelType { get; set; }
        public int? PreferredApartmentRooms { get; set; }
        public bool NotificationsEnabled { get; set; } = true;
        public DateTime UpdatedAt { get; set; }

        // Foreign key
        public int UserId { get; set; }
        public virtual User User { get; set; }
    }
}
