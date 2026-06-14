using JumpIn.Models.DTOs;
using JumpIn.Models.Enums;
using JumpIn.Services.Database;
using JumpIn.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace JumpIn.Services.Services
{
    public class StatisticsService : IStatisticsService
    {
        private readonly JumpInDbContext _context;

        public StatisticsService(JumpInDbContext context)
        {
            _context = context;
        }

        public async Task<AdminStatistics> GetAdminStatisticsAsync()
        {
            var routeAds = await _context.Ads.CountAsync(a => !a.IsDeleted && a.AdType == AdType.Route);
            var carAds = await _context.Ads.CountAsync(a => !a.IsDeleted && a.AdType == AdType.Car);
            var apartmentAds = await _context.Ads.CountAsync(a => !a.IsDeleted && a.AdType == AdType.Apartment);
            var totalAds = await _context.Ads.CountAsync(a => !a.IsDeleted);
            var activeAds = await _context.Ads.CountAsync(a => !a.IsDeleted && a.IsActive);

            var pending = await _context.Requests.CountAsync(r => !r.IsDeleted && r.Status == RequestStatus.Pending);
            var accepted = await _context.Requests.CountAsync(r => !r.IsDeleted && r.Status == RequestStatus.Accepted);
            var declined = await _context.Requests.CountAsync(r => !r.IsDeleted && r.Status == RequestStatus.Declined);
            var totalRequests = await _context.Requests.CountAsync(r => !r.IsDeleted);

            var totalSupport = await _context.SupportMessages.CountAsync();
            var openSupport = await _context.SupportMessages.CountAsync(s => s.Status == SupportStatus.Open);

            var totalReviews = await _context.Reviews.CountAsync();
            var avgRating = totalReviews > 0
                ? await _context.Reviews.AverageAsync(r => (double)r.Rating)
                : 0.0;

            var startOfMonth = new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1);
            var newUsersThisMonth = await _context.Users.CountAsync(u => !u.IsDeleted && u.RegistrationDate >= startOfMonth);

            return new AdminStatistics
            {
                TotalUsers = await _context.Users.CountAsync(u => !u.IsDeleted),
                ActiveUsers = await _context.Users.CountAsync(u => !u.IsDeleted && u.Status == UserStatus.Active),
                BlockedUsers = await _context.Users.CountAsync(u => !u.IsDeleted && u.Status == UserStatus.Blocked),
                VipUsers = await _context.Users.CountAsync(u => !u.IsDeleted && u.IsVip),
                TotalAds = totalAds,
                RouteAds = routeAds,
                CarAds = carAds,
                ApartmentAds = apartmentAds,
                TotalRequests = totalRequests,
                PendingRequests = pending,
                AcceptedRequests = accepted,
                DeclinedRequests = declined,
                TotalReviews = totalReviews,
                TotalSupportMessages = totalSupport,
                OpenSupportMessages = openSupport,
                NewUsersThisMonth = newUsersThisMonth,
                AverageRating = Math.Round(avgRating, 1),
                SupportResponseRate = totalSupport > 0
                    ? Math.Round((double)(totalSupport - openSupport) / totalSupport * 100, 0)
                    : 0,
                AdCompletionRate = totalAds > 0
                    ? Math.Round((double)(totalAds - activeAds) / totalAds * 100, 0)
                    : 0,
                RequestAcceptRate = totalRequests > 0
                    ? Math.Round((double)accepted / totalRequests * 100, 0)
                    : 0,
                AdsByType = new Dictionary<string, int>
                {
                    { "Route", routeAds },
                    { "Car", carAds },
                    { "Apartment", apartmentAds }
                },
                RequestsByStatus = new Dictionary<string, int>
                {
                    { "Pending", pending },
                    { "Accepted", accepted },
                    { "Declined", declined }
                }
            };
        }
    }
}
