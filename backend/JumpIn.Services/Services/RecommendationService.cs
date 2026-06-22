using JumpIn.Models.DTOs;
using JumpIn.Models.Enums;
using JumpIn.Models.Exceptions;
using JumpIn.Services.Database;
using JumpIn.Services.Interfaces;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace JumpIn.Services.Services
{
    public class RecommendationService : IRecommendationService
    {
        private readonly JumpInDbContext _context;

        public RecommendationService(JumpInDbContext context)
        {
            _context = context;
        }

        public async Task<List<AdDTO>> GetRecommendedAdsAsync(Guid userId, int count = 10)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null || user.IsDeleted)
                throw new UserException("User not found.");

            // Get user's interaction history
            var userRequestedAdIds = await _context.Requests
                .Where(r => r.SenderId == userId && !r.IsDeleted)
                .Select(r => r.AdId)
                .ToListAsync();

            var userReviewedAdIds = await _context.Reviews
                .Where(r => r.ReviewerId == userId && r.AdId != null)
                .Select(r => r.AdId!.Value)
                .ToListAsync();

            var interactedAdIds = userRequestedAdIds.Union(userReviewedAdIds).ToHashSet();

            // Get user's preferred ad types based on history
            var preferredTypes = await _context.Requests
                .Where(r => r.SenderId == userId && !r.IsDeleted)
                .Include(r => r.Ad)
                .Select(r => r.Ad.AdType)
                .ToListAsync();

            var typePreferences = preferredTypes
                .GroupBy(t => t)
                .OrderByDescending(g => g.Count())
                .Select(g => g.Key)
                .ToList();

            // Get user's preferred locations
            var preferredLocations = await _context.Requests
                .Where(r => r.SenderId == userId && !r.IsDeleted)
                .Include(r => r.Ad)
                .Select(r => r.Ad.Location ?? r.Ad.LocationFrom ?? r.Ad.LocationTo)
                .Where(l => l != null)
                .ToListAsync();

            // Score all active, non-interacted ads
            var candidateAds = await _context.Ads
                .Include(a => a.User)
                .Where(a => !a.IsDeleted && a.IsActive && a.UserId != userId && !interactedAdIds.Contains(a.Id))
                .ToListAsync();

            var scoredAds = candidateAds.Select(ad =>
            {
                double score = 0;
                // Collect the reasons that fired, so we can explain the recommendation.
                var reasons = new List<string>();

                // Type preference score (40 points max)
                var typeIndex = typePreferences.IndexOf(ad.AdType);
                if (typeIndex >= 0)
                {
                    score += 40 - (typeIndex * 10);
                    reasons.Add(typeIndex == 0
                        ? $"it's a {ad.AdType.ToString().ToLower()} listing, the type you request most"
                        : "it matches a listing type you've requested before");
                }

                // Location match score (30 points)
                var adLocation = ad.Location ?? ad.LocationFrom ?? ad.LocationTo ?? "";
                var adLocationLower = adLocation.ToLower();
                var matchedLocation = preferredLocations.FirstOrDefault(
                    l => l != null && adLocationLower.Contains(l.ToLower()));
                if (matchedLocation != null)
                {
                    score += 30;
                    reasons.Add($"it's in {adLocation}, a location you're interested in");
                }

                // VIP owner bonus (10 points)
                if (ad.User?.IsVip == true)
                {
                    score += 10;
                    reasons.Add("it's posted by a VIP host");
                }

                // Recency bonus (20 points max, linear decay over 30 days)
                var daysSinceCreated = (DateTime.UtcNow - ad.CreatedAt).TotalDays;
                if (daysSinceCreated < 30)
                {
                    score += 20 * (1 - daysSinceCreated / 30);
                    if (daysSinceCreated <= 7)
                        reasons.Add("it was posted recently");
                }

                return new { Ad = ad, Score = score, Reasons = reasons };
            })
            .OrderByDescending(x => x.Score)
            .Take(count)
            .ToList();

            return scoredAds.Select(x =>
            {
                var a = x.Ad;
                var dto = a.Adapt<AdDTO>();
                dto.Type = a.AdType.ToString().ToUpper();
                if (a.User != null)
                {
                    dto.OwnerUsername = a.User.Email;
                    dto.OwnerFullName = $"{a.User.FirstName} {a.User.LastName}".Trim();
                    dto.UserProfileImage = a.User.ProfileImageUrl;
                    dto.IsVipOwner = a.User.IsVip;
                }
                dto.RecommendationReason = BuildRecommendationReason(x.Reasons);
                return dto;
            }).ToList();
        }

        // Turns the matched scoring signals into a normal, user-facing sentence.
        // We deliberately never expose the internal numeric score.
        private static string BuildRecommendationReason(List<string> reasons)
        {
            if (reasons.Count == 0)
                return "Recommended for you based on popular listings.";

            string body = reasons.Count == 1
                ? reasons[0]
                : string.Join(", ", reasons.Take(reasons.Count - 1)) + " and " + reasons[^1];

            return "Recommended because " + body + ".";
        }
    }
}
