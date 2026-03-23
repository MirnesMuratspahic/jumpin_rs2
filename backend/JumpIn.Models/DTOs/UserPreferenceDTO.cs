namespace JumpIn.Models.DTOs
{
    public class UserPreferenceDTO
    {
        public int Id { get; set; }
        public string? PreferredAdType { get; set; }
        public string? PreferredLocation { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public string? PreferredCarBrand { get; set; }
        public string? PreferredFuelType { get; set; }
        public int? PreferredApartmentRooms { get; set; }
        public bool NotificationsEnabled { get; set; }
        public DateTime UpdatedAt { get; set; }
        public int UserId { get; set; }
    }
}
