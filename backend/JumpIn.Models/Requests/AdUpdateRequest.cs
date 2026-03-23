namespace JumpIn.Models.Requests
{
    public class AdUpdateRequest
    {
        public string? Title { get; set; }
        public string? Description { get; set; }
        public decimal? Price { get; set; }
        public DateTime? DateAvailable { get; set; }
        public string? TimeAvailable { get; set; }

        public string? LocationFrom { get; set; }
        public string? LocationTo { get; set; }
        public string? Location { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public double? LatitudeEnd { get; set; }
        public double? LongitudeEnd { get; set; }
        public string? RouteCoordinates { get; set; }

        public string? CarBrand { get; set; }
        public string? CarModel { get; set; }
        public int? CarYear { get; set; }
        public int? CarSeats { get; set; }
        public string? FuelType { get; set; }

        public double? ApartmentArea { get; set; }
        public int? ApartmentRooms { get; set; }
        public string? ApartmentAddress { get; set; }

        public string? ImageUrl { get; set; }
        public bool? IsActive { get; set; }
    }
}
