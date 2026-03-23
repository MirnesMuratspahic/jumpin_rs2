using JumpIn.Models.DTOs;

namespace JumpIn.Services.Interfaces
{
    public interface IRecommendationService
    {
        Task<List<AdDTO>> GetRecommendedAdsAsync(int userId, int count = 10);
    }
}
