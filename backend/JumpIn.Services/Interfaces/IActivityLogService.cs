using JumpIn.Models.DTOs;
using JumpIn.Models.Enums;
using JumpIn.Models.SearchObjects;
using JumpIn.Models.HelperClasses;

namespace JumpIn.Services.Interfaces
{
    public interface IActivityLogService
    {
        Task<PagedResult<ActivityLogDTO>> GetPagedAsync(ActivityLogSearchObject search);
        ActivityLogDTO GetById(int id);
        Task<List<ActivityLogDTO>> GetByUserAsync(int userId, int count = 20);
        Task LogActivityAsync(int userId, ActivityType activityType, string description, int? entityId = null, string? entityType = null, string? ipAddress = null);
    }
}
