using JumpIn.Models.DTOs;

namespace JumpIn.Services.Interfaces
{
    public interface IRecommendationService
    {
        Task<List<AdDTO>> GetRecommendedAdsAsync(Guid userId, int count = 10);
    }
}
