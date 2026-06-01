using System.Collections.Generic;

namespace JumpIn.Models.DTOs
{
    public class AdDTO
    {
        public Guid Id { get; set; }
        public string Title { get; set; }
        public string? Description { get; set; }
        public string Type { get; set; }
        public decimal Price { get; set; }
        public DateTime? DateAvailable { get; set; }
        public string? TimeAvailable { get; set; }

        // Location
        public string? LocationFrom { get; set; }
        public string? LocationTo { get; set; }
        public string? Location { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public double? LatitudeEnd { get; set; }
        public double? LongitudeEnd { get; set; }
        public string? RouteCoordinates { get; set; }

        // Car-specific
        public string? CarBrand { get; set; }
        public string? CarModel { get; set; }
        public int? CarYear { get; set; }
        public int? CarSeats { get; set; }
        public string? FuelType { get; set; }

        // Apartment-specific
        public double? ApartmentArea { get; set; }
        public int? ApartmentRooms { get; set; }
        public string? ApartmentAddress { get; set; }

        public string? ImageUrl { get; set; }
        public List<AdImageDTO>? Images { get; set; }
        public bool IsActive { get; set; }
        public string Status { get; set; } = "Active";
        public DateTime CreatedAt { get; set; }

        // Owner info
        public Guid UserId { get; set; }
        public string? OwnerUsername { get; set; }
        public string? UserProfileImage { get; set; }
        public decimal UserRating { get; set; }
        public bool IsVipOwner { get; set; }
    }
}
