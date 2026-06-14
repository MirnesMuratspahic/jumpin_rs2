using System.Security.Claims;
using JumpIn.Models.Constants;
using JumpIn.Models.DTOs;
using JumpIn.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class RecommendationController : ControllerBase
    {
        private readonly IRecommendationService _recommendationService;

        public RecommendationController(IRecommendationService recommendationService)
        {
            _recommendationService = recommendationService;
        }

        [HttpGet("GetRecommendations/{userId}")]
        public async Task<ActionResult<List<AdDTO>>> GetRecommendations(Guid userId, [FromQuery] int count = 10)
        {
            // A user may only request their own recommendations; admins may request anyone's.
            var currentUserId = Guid.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : (Guid?)null;
            var isAdmin = User.FindFirst(ClaimTypes.Role)?.Value == RoleNames.Admin;
            if (!isAdmin && currentUserId != userId)
                return StatusCode(403, new { errors = new { Forbidden = new[] { "You can only view your own recommendations." } } });

            // Cap the requested count so it can't pull an unbounded list.
            count = Math.Clamp(count, 1, 50);
            return await _recommendationService.GetRecommendedAdsAsync(userId, count);
        }
    }
}
