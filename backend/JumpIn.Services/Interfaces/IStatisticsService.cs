using JumpIn.Models.DTOs;

namespace JumpIn.Services.Interfaces
{
    public interface IStatisticsService
    {
        Task<AdminStatistics> GetAdminStatisticsAsync();
    }
}
