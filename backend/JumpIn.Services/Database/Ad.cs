using JumpIn.Models.Enums;

namespace JumpIn.Services.Database
{
    public class Ad : ISoftDeletable
    {
        public Guid Id { get; set; }
        public string Title { get; set; }
        public string? Description { get; set; }
        public AdType AdType { get; set; }
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
        public bool IsActive { get; set; }
        public AdStatus? Status { get; set; }
        public DateTime CreatedAt { get; set; }

        // Foreign key
        public Guid UserId { get; set; }
        public virtual User User { get; set; }

        // Audit trail for status changes: which user ended the ad, and when.
        public Guid? EndedByUserId { get; set; }
        public DateTime? EndedAt { get; set; }

        // Soft delete
        public bool IsDeleted { get; set; }
        public DateTime? DeleteTime { get; set; }
        // Which user performed the delete (owner or admin).
        public Guid? DeletedByUserId { get; set; }

        // Navigation
        public virtual ICollection<Request> Requests { get; set; } = new List<Request>();
        public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
        public virtual ICollection<Favorite> Favorites { get; set; } = new List<Favorite>();
        public virtual ICollection<AdImage> AdImages { get; set; } = new List<AdImage>();
    }
}
