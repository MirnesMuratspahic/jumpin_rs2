using JumpIn.Models.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace JumpIn.Services.Database
{
    public class DatabaseSeeder
    {
        private readonly JumpInDbContext _context;
        private readonly ILogger _logger;

        public DatabaseSeeder(JumpInDbContext context, ILogger logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task SeedAsync()
        {
            _logger.LogInformation("[SEED] Starting backfill of TotalAds with SQL...");
            try
            {
                // Use raw SQL to update TotalAds - more reliable than EF
                await _context.Database.ExecuteSqlRawAsync(@"
                    UPDATE [Users]
                    SET TotalAds = (SELECT COUNT(*) FROM [Ads] WHERE [Ads].UserId = [Users].Id AND [Ads].IsDeleted = 0)
                    WHERE IsDeleted = 0
                ");
                _logger.LogInformation("[SEED] TotalAds backfill complete");
            }
            catch (Exception ex)
            {
                _logger.LogInformation($"[SEED] Backfill skipped - tables may not exist yet: {ex.Message}");
            }

            try
            {
                if (_context.Users.Any())
                {
                    _logger.LogInformation("[SEED] Users already exist, skipping new seeder");
                    _logger.LogInformation("[SEED] Backfill complete");
                    return;
                }
            }
            catch (Exception ex)
            {
                _logger.LogInformation($"[SEED] Could not check existing users - tables may not exist yet: {ex.Message}");
                _logger.LogInformation("[SEED] Will continue with seeding...");
            }
            _logger.LogInformation("[SEED] Starting database seed...");

            // Seed Admin
            var admin = new User
            {
                Id = Guid.NewGuid(),
                FirstName = "Admin",
                LastName = "User",
                Email = "admin@jumpin.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("test1234"),
                Phone = "+387 61 000 001",
                ProfileImageUrl = "https://i.pravatar.cc/300?u=admin@jumpin.com",
                RegistrationDate = DateTime.UtcNow,
                Status = UserStatus.Active,
                Role = UserRole.Admin,
                IsVip = false
            };
            _context.Users.Add(admin);

            // Seed Mobile user (password: test)
            var mobile = new User
            {
                Id = Guid.NewGuid(),
                FirstName = "Mobile",
                LastName = "User",
                Email = "mobile@jumpin.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("test1234"),
                Phone = "+387 61 000 002",
                ProfileImageUrl = "https://i.pravatar.cc/300?u=mobile@jumpin.com",
                RegistrationDate = DateTime.UtcNow.AddDays(-30),
                Status = UserStatus.Active,
                Role = UserRole.Customer,
                IsVip = false
            };
            _context.Users.Add(mobile);

            // Seed Regular Users
            var users = new List<User>();
            var userNames = new[]
            {
                ("Alex", "Carter"), ("Jordan", "Bennett"), ("Sam", "Parker"),
                ("Jamie", "Brooks"), ("Chris", "Morgan"), ("Taylor", "Reed"),
                ("Casey", "Walker"), ("Riley", "Hayes"), ("Morgan", "Bailey"), ("Drew", "Foster")
            };

            foreach (var (first, last) in userNames)
            {
                var user = new User
                {
                    Id = Guid.NewGuid(),
                    FirstName = first,
                    LastName = last,
                    Email = $"{first.ToLower()}.{last.ToLower()}@gmail.com",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("test1234"),
                    Phone = $"+387 6{Random.Shared.Next(1, 4)} {Random.Shared.Next(100, 999)} {Random.Shared.Next(100, 999)}",
                    ProfileImageUrl = $"https://i.pravatar.cc/300?u={first.ToLower()}.{last.ToLower()}@gmail.com",
                    RegistrationDate = DateTime.UtcNow.AddDays(-Random.Shared.Next(1, 90)),
                    Status = UserStatus.Active,
                    Role = UserRole.Customer,
                    IsVip = first == "Alex" || first == "Jordan",
                    VipActivatedAt = first == "Alex" || first == "Jordan" ? DateTime.UtcNow.AddDays(-10) : null,
                    VipExpiresAt = first == "Alex" || first == "Jordan" ? DateTime.UtcNow.AddDays(20) : null
                };
                users.Add(user);
            }
            _context.Users.AddRange(users);
            await _context.SaveChangesAsync();

            // Seed Cities
            var cities = new List<City>
            {
                new City { Id = Guid.NewGuid(), Name = "Sarajevo", Latitude = 43.8563, Longitude = 18.4131 },
                new City { Id = Guid.NewGuid(), Name = "Mostar", Latitude = 43.3438, Longitude = 17.8078 },
                new City { Id = Guid.NewGuid(), Name = "Banja Luka", Latitude = 44.7722, Longitude = 17.1910 },
                new City { Id = Guid.NewGuid(), Name = "Tuzla", Latitude = 44.5384, Longitude = 18.6737 },
                new City { Id = Guid.NewGuid(), Name = "Zenica", Latitude = 44.2037, Longitude = 17.9078 },
                new City { Id = Guid.NewGuid(), Name = "Bijeljina", Latitude = 44.7566, Longitude = 19.2144 },
                new City { Id = Guid.NewGuid(), Name = "Brčko", Latitude = 44.8726, Longitude = 18.8100 },
                new City { Id = Guid.NewGuid(), Name = "Prijedor", Latitude = 44.9808, Longitude = 16.7134 },
                new City { Id = Guid.NewGuid(), Name = "Doboj", Latitude = 44.7319, Longitude = 18.0853 },
                new City { Id = Guid.NewGuid(), Name = "Cazin", Latitude = 44.9667, Longitude = 15.9431 },
                new City { Id = Guid.NewGuid(), Name = "Bihać", Latitude = 44.8169, Longitude = 15.8708 },
                new City { Id = Guid.NewGuid(), Name = "Trebinje", Latitude = 42.7119, Longitude = 18.3436 },
                new City { Id = Guid.NewGuid(), Name = "Livno", Latitude = 43.8269, Longitude = 17.0081 },
                new City { Id = Guid.NewGuid(), Name = "Goražde", Latitude = 43.6667, Longitude = 18.9764 },
                new City { Id = Guid.NewGuid(), Name = "Travnik", Latitude = 44.2264, Longitude = 17.6658 },
                new City { Id = Guid.NewGuid(), Name = "Bugojno", Latitude = 44.0572, Longitude = 17.4508 },
                new City { Id = Guid.NewGuid(), Name = "Konjic", Latitude = 43.6517, Longitude = 17.9606 },
                new City { Id = Guid.NewGuid(), Name = "Visoko", Latitude = 43.9889, Longitude = 18.1781 },
                new City { Id = Guid.NewGuid(), Name = "Gradačac", Latitude = 44.8781, Longitude = 18.4275 },
                new City { Id = Guid.NewGuid(), Name = "Gračanica", Latitude = 44.7042, Longitude = 18.3083 },
                new City { Id = Guid.NewGuid(), Name = "Lukavac", Latitude = 44.5417, Longitude = 18.5278 },
                new City { Id = Guid.NewGuid(), Name = "Srebrenik", Latitude = 44.7081, Longitude = 18.4892 },
                new City { Id = Guid.NewGuid(), Name = "Tešanj", Latitude = 44.6117, Longitude = 17.9861 },
                new City { Id = Guid.NewGuid(), Name = "Maglaj", Latitude = 44.5478, Longitude = 18.1000 },
                new City { Id = Guid.NewGuid(), Name = "Zavidovići", Latitude = 44.4464, Longitude = 18.1500 },
                new City { Id = Guid.NewGuid(), Name = "Kakanj", Latitude = 44.1286, Longitude = 18.1200 },
                new City { Id = Guid.NewGuid(), Name = "Sanski Most", Latitude = 44.7667, Longitude = 16.6667 },
                new City { Id = Guid.NewGuid(), Name = "Ključ", Latitude = 44.5333, Longitude = 16.7833 },
                new City { Id = Guid.NewGuid(), Name = "Jajce", Latitude = 44.3414, Longitude = 17.2708 },
                new City { Id = Guid.NewGuid(), Name = "Vitez", Latitude = 44.1547, Longitude = 17.7917 },
                new City { Id = Guid.NewGuid(), Name = "Kiseljak", Latitude = 43.9431, Longitude = 18.0778 },
                new City { Id = Guid.NewGuid(), Name = "Fojnica", Latitude = 43.9614, Longitude = 17.8933 },
                new City { Id = Guid.NewGuid(), Name = "Stolac", Latitude = 43.0844, Longitude = 17.9600 },
                new City { Id = Guid.NewGuid(), Name = "Čapljina", Latitude = 43.1214, Longitude = 17.6856 },
                new City { Id = Guid.NewGuid(), Name = "Neum", Latitude = 42.9236, Longitude = 17.6158 },
                new City { Id = Guid.NewGuid(), Name = "Široki Brijeg", Latitude = 43.3822, Longitude = 17.5936 },
                new City { Id = Guid.NewGuid(), Name = "Grude", Latitude = 43.3756, Longitude = 17.3978 },
                new City { Id = Guid.NewGuid(), Name = "Posušje", Latitude = 43.4714, Longitude = 17.3264 },
                new City { Id = Guid.NewGuid(), Name = "Tomislavgrad", Latitude = 43.7178, Longitude = 17.2250 },
                new City { Id = Guid.NewGuid(), Name = "Kupres", Latitude = 43.9833, Longitude = 17.2833 },
                new City { Id = Guid.NewGuid(), Name = "Glamoč", Latitude = 44.0500, Longitude = 16.8500 },
                new City { Id = Guid.NewGuid(), Name = "Drvar", Latitude = 44.3700, Longitude = 16.3831 },
                new City { Id = Guid.NewGuid(), Name = "Bosanski Petrovac", Latitude = 44.5533, Longitude = 16.3700 },
                new City { Id = Guid.NewGuid(), Name = "Velika Kladuša", Latitude = 45.1872, Longitude = 15.8056 },
                new City { Id = Guid.NewGuid(), Name = "Bosanska Krupa", Latitude = 44.8833, Longitude = 16.1500 },
                new City { Id = Guid.NewGuid(), Name = "Zvornik", Latitude = 44.3864, Longitude = 19.1025 },
                new City { Id = Guid.NewGuid(), Name = "Vlasenica", Latitude = 44.1833, Longitude = 18.9333 },
                new City { Id = Guid.NewGuid(), Name = "Srebrenica", Latitude = 44.1047, Longitude = 19.2969 },
                new City { Id = Guid.NewGuid(), Name = "Višegrad", Latitude = 43.7836, Longitude = 19.2925 },
                new City { Id = Guid.NewGuid(), Name = "Foča", Latitude = 43.5053, Longitude = 18.7756 },
                new City { Id = Guid.NewGuid(), Name = "Rogatica", Latitude = 43.7997, Longitude = 19.0036 },
                new City { Id = Guid.NewGuid(), Name = "Sokolac", Latitude = 43.9381, Longitude = 18.7992 },
                new City { Id = Guid.NewGuid(), Name = "Pale", Latitude = 43.8167, Longitude = 18.5697 },
                new City { Id = Guid.NewGuid(), Name = "Istočno Sarajevo", Latitude = 43.8194, Longitude = 18.4847 },
                new City { Id = Guid.NewGuid(), Name = "Laktaši", Latitude = 44.8500, Longitude = 17.3000 },
                new City { Id = Guid.NewGuid(), Name = "Gradiška", Latitude = 45.1447, Longitude = 17.2544 },
                new City { Id = Guid.NewGuid(), Name = "Prnjavor", Latitude = 44.8667, Longitude = 17.6625 },
                new City { Id = Guid.NewGuid(), Name = "Derventa", Latitude = 44.9783, Longitude = 17.9083 },
                new City { Id = Guid.NewGuid(), Name = "Modriča", Latitude = 44.9556, Longitude = 18.3000 },
                new City { Id = Guid.NewGuid(), Name = "Šamac", Latitude = 45.0667, Longitude = 18.4667 },
                new City { Id = Guid.NewGuid(), Name = "Orašje", Latitude = 45.0333, Longitude = 18.6833 },
                new City { Id = Guid.NewGuid(), Name = "Odžak", Latitude = 45.0083, Longitude = 18.3250 },
                new City { Id = Guid.NewGuid(), Name = "Žepče", Latitude = 44.4267, Longitude = 18.0383 },
                new City { Id = Guid.NewGuid(), Name = "Usora", Latitude = 44.5667, Longitude = 17.9833 },
                new City { Id = Guid.NewGuid(), Name = "Mrkonjić Grad", Latitude = 44.4167, Longitude = 17.0833 }
            };
            _context.Cities.AddRange(cities);
            await _context.SaveChangesAsync();

            // Seed Ads
            var ads = new List<Ad>
            {
                // Routes
                new Ad
                {
                    Id = Guid.NewGuid(),
                    Title = "Mostar - Sarajevo Daily Route",
                    Description = "Comfortable ride from Mostar to Sarajevo, daily departure at 8:00 AM.",
                    AdType = AdType.Route,
                    Price = 25,
                    DateAvailable = DateTime.UtcNow.AddDays(5),
                    TimeAvailable = "08:00",
                    LocationFrom = "Mostar",
                    LocationTo = "Sarajevo",
                    Latitude = 43.3438,
                    Longitude = 17.8078,
                    LatitudeEnd = 43.8563,
                    LongitudeEnd = 18.4131,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-3),
                    UserId = users[0].Id
                },
                new Ad
                {
                    Id = Guid.NewGuid(),
                    Title = "Sarajevo - Tuzla Weekend Route",
                    Description = "Weekend trips from Sarajevo to Tuzla. AC, comfortable seats.",
                    AdType = AdType.Route,
                    Price = 20,
                    DateAvailable = DateTime.UtcNow.AddDays(7),
                    TimeAvailable = "09:00",
                    LocationFrom = "Sarajevo",
                    LocationTo = "Tuzla",
                    Latitude = 43.8563,
                    Longitude = 18.4131,
                    LatitudeEnd = 44.5384,
                    LongitudeEnd = 18.6737,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-5),
                    UserId = users[1].Id
                },
                // Cars
                new Ad
                {
                    Id = Guid.NewGuid(),
                    Title = "VW Golf 7 for Rent",
                    Description = "Volkswagen Golf 7, 2018, diesel, 5 seats. Daily rental available.",
                    AdType = AdType.Car,
                    Price = 50,
                    Location = "Mostar",
                    Latitude = 43.3438,
                    Longitude = 17.8078,
                    CarBrand = "Volkswagen",
                    CarModel = "Golf 7",
                    CarYear = 2018,
                    CarSeats = 5,
                    FuelType = "Diesel",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-2),
                    UserId = users[2].Id
                },
                new Ad
                {
                    Id = Guid.NewGuid(),
                    Title = "BMW 3 Series - Premium Rental",
                    Description = "BMW 320d, 2020, automatic, premium interior. Perfect for business trips.",
                    AdType = AdType.Car,
                    Price = 80,
                    Location = "Sarajevo",
                    Latitude = 43.8563,
                    Longitude = 18.4131,
                    CarBrand = "BMW",
                    CarModel = "320d",
                    CarYear = 2020,
                    CarSeats = 5,
                    FuelType = "Diesel",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-1),
                    UserId = users[3].Id
                },
                // Apartments
                new Ad
                {
                    Id = Guid.NewGuid(),
                    Title = "Cozy Studio Apartment - Old Town Mostar",
                    Description = "Beautiful studio apartment near Old Bridge. Perfect for tourists. WiFi, AC, kitchen.",
                    AdType = AdType.Apartment,
                    Price = 45,
                    Location = "Mostar, Old Town",
                    Latitude = 43.3372,
                    Longitude = 17.8149,
                    ApartmentArea = 35,
                    ApartmentRooms = 1,
                    ApartmentAddress = "Kujundziluk 12, Mostar",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-4),
                    UserId = users[4].Id
                },
                new Ad
                {
                    Id = Guid.NewGuid(),
                    Title = "Modern 2BR Apartment Sarajevo Center",
                    Description = "Spacious 2-bedroom apartment in Sarajevo city center. Walking distance to Bascarsija.",
                    AdType = AdType.Apartment,
                    Price = 70,
                    Location = "Sarajevo, Center",
                    Latitude = 43.8590,
                    Longitude = 18.4310,
                    ApartmentArea = 65,
                    ApartmentRooms = 2,
                    ApartmentAddress = "Ferhadija 15, Sarajevo",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-6),
                    UserId = users[5].Id
                }
            };
            _context.Ads.AddRange(ads);
            await _context.SaveChangesAsync();

            // Seed one main image per ad — real category-appropriate photos
            // (ads are in order: Route, Route, Car, Car, Apartment, Apartment).
            var adImageUrls = new[]
            {
                "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800&q=80", // route / road
                "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=800&q=80", // route / road
                "https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?w=800&q=80", // car
                "https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800&q=80",    // car
                "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&q=80", // apartment
                "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&q=80"  // apartment
            };
            var adImages = ads.Select((ad, i) => new AdImage
            {
                Id = Guid.NewGuid(),
                AdId = ad.Id,
                ImageUrl = adImageUrls[i % adImageUrls.Length],
                IsMainImage = true,
                DisplayOrder = 0,
                CreatedAt = DateTime.UtcNow
            }).ToList();
            _context.AdImages.AddRange(adImages);
            await _context.SaveChangesAsync();

            // Seed Requests
            var requests = new List<Request>
            {
                new Request
                {
                    Id = Guid.NewGuid(),
                    RequestNumber = "REQ-20260201-ABC001",
                    SenderId = users[1].Id,
                    SenderEmail = users[1].Email,
                    ReceiverId = users[0].Id,
                    ReceiverEmail = users[0].Email,
                    AdId = ads[0].Id,
                    Status = RequestStatus.Pending,
                    Message = "I would like to join the route to Sarajevo.",
                    CreatedAt = DateTime.UtcNow.AddDays(-1)
                },
                new Request
                {
                    Id = Guid.NewGuid(),
                    RequestNumber = "REQ-20260201-ABC002",
                    SenderId = users[3].Id,
                    SenderEmail = users[3].Email,
                    ReceiverId = users[4].Id,
                    ReceiverEmail = users[4].Email,
                    AdId = ads[4].Id,
                    Status = RequestStatus.Accepted,
                    Message = "I'd like to rent the apartment for next weekend.",
                    CreatedAt = DateTime.UtcNow.AddDays(-3),
                    RespondedAt = DateTime.UtcNow.AddDays(-2)
                }
            };
            _context.Requests.AddRange(requests);

            // Seed Reviews
            var reviews = new List<Review>
            {
                new Review { Id = Guid.NewGuid(), Rating = 5, Comment = "Great driver, very punctual!", CreatedAt = DateTime.UtcNow.AddDays(-10), ReviewerId = users[1].Id, ReviewedUserId = users[0].Id, ReviewerEmail = users[1].Email, ReviewedUserEmail = users[0].Email, AdId = ads[0].Id },
                new Review { Id = Guid.NewGuid(), Rating = 4, Comment = "Nice apartment, clean and well located.", CreatedAt = DateTime.UtcNow.AddDays(-5), ReviewerId = users[3].Id, ReviewedUserId = users[4].Id, ReviewerEmail = users[3].Email, ReviewedUserEmail = users[4].Email, AdId = ads[1].Id },
                new Review { Id = Guid.NewGuid(), Rating = 5, Comment = "Excellent service, highly recommended!", CreatedAt = DateTime.UtcNow.AddDays(-7), ReviewerId = users[5].Id, ReviewedUserId = users[2].Id, ReviewerEmail = users[5].Email, ReviewedUserEmail = users[2].Email, AdId = ads[2].Id }
            };
            _context.Reviews.AddRange(reviews);

            // Seed Support Messages
            var supportMessages = new List<SupportMessage>
            {
                new SupportMessage
                {
                    Id = Guid.NewGuid(),
                    Subject = "How to become VIP?",
                    Message = "I would like to know how to activate VIP membership on my account.",
                    Status = SupportStatus.Open,
                    CreatedAt = DateTime.UtcNow.AddDays(-2),
                    UserId = users[2].Id
                },
                new SupportMessage
                {
                    Id = Guid.NewGuid(),
                    Subject = "Issue with request",
                    Message = "I sent a request but the owner hasn't responded for 5 days.",
                    Response = "We will contact the ad owner and get back to you.",
                    Status = SupportStatus.InProgress,
                    CreatedAt = DateTime.UtcNow.AddDays(-4),
                    RespondedAt = DateTime.UtcNow.AddDays(-3),
                    UserId = users[1].Id
                }
            };
            _context.SupportMessages.AddRange(supportMessages);

            await _context.SaveChangesAsync();
            _logger.LogInformation("[SEED] Completed - seeded users and ads");
        }
    }
}
