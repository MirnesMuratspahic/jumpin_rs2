using JumpIn.Models.DTOs;
using JumpIn.Models.Enums;
using JumpIn.Services.Database;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JumpIn.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class StatisticsController : ControllerBase
    {
        private readonly JumpInDbContext _context;

        public StatisticsController(JumpInDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<AdminStatistics> GetAdminStatistics()
        {
            return new AdminStatistics
            {
                TotalUsers = await _context.Users.CountAsync(u => !u.IsDeleted),
                ActiveUsers = await _context.Users.CountAsync(u => !u.IsDeleted && u.Status == UserStatus.Active),
                BlockedUsers = await _context.Users.CountAsync(u => !u.IsDeleted && u.Status == UserStatus.Blocked),
                VipUsers = await _context.Users.CountAsync(u => !u.IsDeleted && u.IsVip),
                TotalAds = await _context.Ads.CountAsync(a => !a.IsDeleted),
                RouteAds = await _context.Ads.CountAsync(a => !a.IsDeleted && a.AdType == AdType.Route),
                CarAds = await _context.Ads.CountAsync(a => !a.IsDeleted && a.AdType == AdType.Car),
                ApartmentAds = await _context.Ads.CountAsync(a => !a.IsDeleted && a.AdType == AdType.Apartment),
                TotalRequests = await _context.Requests.CountAsync(r => !r.IsDeleted),
                PendingRequests = await _context.Requests.CountAsync(r => !r.IsDeleted && r.Status == RequestStatus.Pending),
                AcceptedRequests = await _context.Requests.CountAsync(r => !r.IsDeleted && r.Status == RequestStatus.Accepted),
                DeclinedRequests = await _context.Requests.CountAsync(r => !r.IsDeleted && r.Status == RequestStatus.Declined),
                TotalReviews = await _context.Reviews.CountAsync(),
                TotalSupportMessages = await _context.SupportMessages.CountAsync(),
                OpenSupportMessages = await _context.SupportMessages.CountAsync(s => s.Status == SupportStatus.Open)
            };
        }
    }
}
