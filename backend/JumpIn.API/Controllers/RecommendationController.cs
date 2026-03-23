using JumpIn.Models.DTOs;
using JumpIn.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RecommendationController : ControllerBase
    {
        private readonly IRecommendationService _recommendationService;

        public RecommendationController(IRecommendationService recommendationService)
        {
            _recommendationService = recommendationService;
        }

        [HttpGet("GetRecommendations/{userId}")]
        public async Task<List<AdDTO>> GetRecommendations(int userId, [FromQuery] int count = 10)
        {
            return await _recommendationService.GetRecommendedAdsAsync(userId, count);
        }
    }
}
