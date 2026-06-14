using JumpIn.Models.DTOs;
using JumpIn.Models.Enums;
using JumpIn.Models.SearchObjects;
using JumpIn.Models.HelperClasses;

namespace JumpIn.Services.Interfaces
{
    public interface IActivityLogService
    {
        Task<PagedResult<ActivityLogDTO>> GetPagedAsync(ActivityLogSearchObject search);
        ActivityLogDTO GetById(Guid id);
        Task<List<ActivityLogDTO>> GetByUserAsync(Guid userId, int count = 20);
        Task LogActivityAsync(Guid userId, ActivityType activityType, string description, Guid? entityId = null, string? entityType = null, string? ipAddress = null);
    }
}
