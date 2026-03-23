using JumpIn.Models.Enums;

namespace JumpIn.Services.Database
{
    public class DatabaseSeeder
    {
        private readonly JumpInDbContext _context;

        public DatabaseSeeder(JumpInDbContext context)
        {
            _context = context;
        }

        public async Task SeedAsync()
        {
            if (_context.Users.Any())
                return;

            // Seed Admin - Desktop login (username: desktop, password: test)
            var desktop = new User
            {
                FirstName = "Desktop",
                LastName = "Admin",
                Username = "desktop",
                Email = "desktop@jumpin.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("test"),
                Phone = "+387 61 000 000",
                RegistrationDate = DateTime.UtcNow,
                Status = UserStatus.Active,
                Role = UserRole.Admin,
                IsVip = false
            };
            _context.Users.Add(desktop);

            // Seed Admin - additional admin account (username: admin, password: test)
            var admin = new User
            {
                FirstName = "Admin",
                LastName = "User",
                Username = "admin",
                Email = "admin@jumpin.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("test"),
                Phone = "+387 61 000 001",
                RegistrationDate = DateTime.UtcNow,
                Status = UserStatus.Active,
                Role = UserRole.Admin,
                IsVip = false
            };
            _context.Users.Add(admin);

            // Seed Mobile user (username: mobile, password: test)
            var mobile = new User
            {
                FirstName = "Mobile",
                LastName = "User",
                Username = "mobile",
                Email = "mobile@jumpin.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("test"),
                Phone = "+387 61 000 002",
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
                ("Mirnes", "Muratspahic"), ("Amel", "Music"), ("Denis", "Music"),
                ("Sara", "Hadzic"), ("Kenan", "Begovic"), ("Amina", "Causevic"),
                ("Edin", "Spahic"), ("Lejla", "Dizdar"), ("Tarik", "Mesic"), ("Nadia", "Imamovic")
            };

            foreach (var (first, last) in userNames)
            {
                var user = new User
                {
                    FirstName = first,
                    LastName = last,
                    Username = $"{first.ToLower()}.{last.ToLower()}",
                    Email = $"{first.ToLower()}.{last.ToLower()}@gmail.com",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("test"),
                    Phone = $"+387 6{Random.Shared.Next(1, 4)} {Random.Shared.Next(100, 999)} {Random.Shared.Next(100, 999)}",
                    RegistrationDate = DateTime.UtcNow.AddDays(-Random.Shared.Next(1, 90)),
                    Status = UserStatus.Active,
                    Role = UserRole.Customer,
                    IsVip = first == "Mirnes" || first == "Sara",
                    VipActivatedAt = first == "Mirnes" || first == "Sara" ? DateTime.UtcNow.AddDays(-10) : null,
                    VipExpiresAt = first == "Mirnes" || first == "Sara" ? DateTime.UtcNow.AddDays(20) : null
                };
                users.Add(user);
            }
            _context.Users.AddRange(users);
            await _context.SaveChangesAsync();

            // Seed Cities
            var cities = new List<City>
            {
                new City { Name = "Sarajevo", Latitude = 43.8563, Longitude = 18.4131 },
                new City { Name = "Mostar", Latitude = 43.3438, Longitude = 17.8078 },
                new City { Name = "Banja Luka", Latitude = 44.7722, Longitude = 17.1910 },
                new City { Name = "Tuzla", Latitude = 44.5384, Longitude = 18.6737 },
                new City { Name = "Zenica", Latitude = 44.2037, Longitude = 17.9078 },
                new City { Name = "Bijeljina", Latitude = 44.7566, Longitude = 19.2144 },
                new City { Name = "Brčko", Latitude = 44.8726, Longitude = 18.8100 },
                new City { Name = "Prijedor", Latitude = 44.9808, Longitude = 16.7134 },
                new City { Name = "Doboj", Latitude = 44.7319, Longitude = 18.0853 },
                new City { Name = "Cazin", Latitude = 44.9667, Longitude = 15.9431 },
                new City { Name = "Bihać", Latitude = 44.8169, Longitude = 15.8708 },
                new City { Name = "Trebinje", Latitude = 42.7119, Longitude = 18.3436 },
                new City { Name = "Livno", Latitude = 43.8269, Longitude = 17.0081 },
                new City { Name = "Goražde", Latitude = 43.6667, Longitude = 18.9764 },
                new City { Name = "Travnik", Latitude = 44.2264, Longitude = 17.6658 },
                new City { Name = "Bugojno", Latitude = 44.0572, Longitude = 17.4508 },
                new City { Name = "Konjic", Latitude = 43.6517, Longitude = 17.9606 },
                new City { Name = "Visoko", Latitude = 43.9889, Longitude = 18.1781 },
                new City { Name = "Gradačac", Latitude = 44.8781, Longitude = 18.4275 },
                new City { Name = "Gračanica", Latitude = 44.7042, Longitude = 18.3083 },
                new City { Name = "Lukavac", Latitude = 44.5417, Longitude = 18.5278 },
                new City { Name = "Srebrenik", Latitude = 44.7081, Longitude = 18.4892 },
                new City { Name = "Tešanj", Latitude = 44.6117, Longitude = 17.9861 },
                new City { Name = "Maglaj", Latitude = 44.5478, Longitude = 18.1000 },
                new City { Name = "Zavidovići", Latitude = 44.4464, Longitude = 18.1500 },
                new City { Name = "Kakanj", Latitude = 44.1286, Longitude = 18.1200 },
                new City { Name = "Sanski Most", Latitude = 44.7667, Longitude = 16.6667 },
                new City { Name = "Ključ", Latitude = 44.5333, Longitude = 16.7833 },
                new City { Name = "Jajce", Latitude = 44.3414, Longitude = 17.2708 },
                new City { Name = "Vitez", Latitude = 44.1547, Longitude = 17.7917 },
                new City { Name = "Kiseljak", Latitude = 43.9431, Longitude = 18.0778 },
                new City { Name = "Fojnica", Latitude = 43.9614, Longitude = 17.8933 },
                new City { Name = "Stolac", Latitude = 43.0844, Longitude = 17.9600 },
                new City { Name = "Čapljina", Latitude = 43.1214, Longitude = 17.6856 },
                new City { Name = "Neum", Latitude = 42.9236, Longitude = 17.6158 },
                new City { Name = "Široki Brijeg", Latitude = 43.3822, Longitude = 17.5936 },
                new City { Name = "Grude", Latitude = 43.3756, Longitude = 17.3978 },
                new City { Name = "Posušje", Latitude = 43.4714, Longitude = 17.3264 },
                new City { Name = "Tomislavgrad", Latitude = 43.7178, Longitude = 17.2250 },
                new City { Name = "Kupres", Latitude = 43.9833, Longitude = 17.2833 },
                new City { Name = "Glamoč", Latitude = 44.0500, Longitude = 16.8500 },
                new City { Name = "Drvar", Latitude = 44.3700, Longitude = 16.3831 },
                new City { Name = "Bosanski Petrovac", Latitude = 44.5533, Longitude = 16.3700 },
                new City { Name = "Velika Kladuša", Latitude = 45.1872, Longitude = 15.8056 },
                new City { Name = "Bosanska Krupa", Latitude = 44.8833, Longitude = 16.1500 },
                new City { Name = "Zvornik", Latitude = 44.3864, Longitude = 19.1025 },
                new City { Name = "Vlasenica", Latitude = 44.1833, Longitude = 18.9333 },
                new City { Name = "Srebrenica", Latitude = 44.1047, Longitude = 19.2969 },
                new City { Name = "Višegrad", Latitude = 43.7836, Longitude = 19.2925 },
                new City { Name = "Foča", Latitude = 43.5053, Longitude = 18.7756 },
                new City { Name = "Rogatica", Latitude = 43.7997, Longitude = 19.0036 },
                new City { Name = "Sokolac", Latitude = 43.9381, Longitude = 18.7992 },
                new City { Name = "Pale", Latitude = 43.8167, Longitude = 18.5697 },
                new City { Name = "Istočno Sarajevo", Latitude = 43.8194, Longitude = 18.4847 },
                new City { Name = "Laktaši", Latitude = 44.8500, Longitude = 17.3000 },
                new City { Name = "Gradiška", Latitude = 45.1447, Longitude = 17.2544 },
                new City { Name = "Prnjavor", Latitude = 44.8667, Longitude = 17.6625 },
                new City { Name = "Derventa", Latitude = 44.9783, Longitude = 17.9083 },
                new City { Name = "Modriča", Latitude = 44.9556, Longitude = 18.3000 },
                new City { Name = "Šamac", Latitude = 45.0667, Longitude = 18.4667 },
                new City { Name = "Orašje", Latitude = 45.0333, Longitude = 18.6833 },
                new City { Name = "Odžak", Latitude = 45.0083, Longitude = 18.3250 },
                new City { Name = "Žepče", Latitude = 44.4267, Longitude = 18.0383 },
                new City { Name = "Usora", Latitude = 44.5667, Longitude = 17.9833 },
                new City { Name = "Mrkonjić Grad", Latitude = 44.4167, Longitude = 17.0833 }
            };
            _context.Cities.AddRange(cities);
            await _context.SaveChangesAsync();

            // Seed Ads
            var ads = new List<Ad>
            {
                // Routes
                new Ad
                {
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

            // Seed Requests
            var requests = new List<Request>
            {
                new Request
                {
                    RequestNumber = "REQ-20260201-ABC001",
                    SenderId = users[1].Id,
                    ReceiverId = users[0].Id,
                    AdId = ads[0].Id,
                    Status = RequestStatus.Pending,
                    Message = "I would like to join the route to Sarajevo.",
                    CreatedAt = DateTime.UtcNow.AddDays(-1)
                },
                new Request
                {
                    RequestNumber = "REQ-20260201-ABC002",
                    SenderId = users[3].Id,
                    ReceiverId = users[4].Id,
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
                new Review { Rating = 5, Comment = "Great driver, very punctual!", CreatedAt = DateTime.UtcNow.AddDays(-10), ReviewerId = users[1].Id, ReviewedUserId = users[0].Id },
                new Review { Rating = 4, Comment = "Nice apartment, clean and well located.", CreatedAt = DateTime.UtcNow.AddDays(-5), ReviewerId = users[3].Id, ReviewedUserId = users[4].Id },
                new Review { Rating = 5, Comment = "Excellent service, highly recommended!", CreatedAt = DateTime.UtcNow.AddDays(-7), ReviewerId = users[5].Id, ReviewedUserId = users[2].Id }
            };
            _context.Reviews.AddRange(reviews);

            // Seed Support Messages
            var supportMessages = new List<SupportMessage>
            {
                new SupportMessage
                {
                    Subject = "How to become VIP?",
                    Message = "I would like to know how to activate VIP membership on my account.",
                    Status = SupportStatus.Open,
                    CreatedAt = DateTime.UtcNow.AddDays(-2),
                    UserId = users[2].Id
                },
                new SupportMessage
                {
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
        }
    }
}
