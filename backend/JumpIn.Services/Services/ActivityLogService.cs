using JumpIn.Models.DTOs;
using JumpIn.Models.Enums;
using JumpIn.Models.Exceptions;
using JumpIn.Models.HelperClasses;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseServices;
using JumpIn.Services.Database;
using JumpIn.Services.Interfaces;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace JumpIn.Services.Services
{
    public class ActivityLogService : IActivityLogService
    {
        private readonly JumpInDbContext _context;

        public ActivityLogService(JumpInDbContext context)
        {
            _context = context;
        }

        public async Task<PagedResult<ActivityLogDTO>> GetPagedAsync(ActivityLogSearchObject search)
        {
            var query = _context.ActivityLogs
                .Include(al => al.User)
                .AsQueryable();

            if (search.UserId.HasValue)
                query = query.Where(al => al.UserId == search.UserId.Value);

            if (!string.IsNullOrEmpty(search.ActivityType))
            {
                if (Enum.TryParse<ActivityType>(search.ActivityType, true, out var type))
                    query = query.Where(al => al.ActivityType == type);
            }

            if (search.DateFrom.HasValue)
                query = query.Where(al => al.CreatedAt >= search.DateFrom.Value);

            if (search.DateTo.HasValue)
                query = query.Where(al => al.CreatedAt <= search.DateTo.Value);

            query = query.OrderByDescending(al => al.CreatedAt);

            var totalCount = await query.CountAsync();

            query = query.ApplyPaging(search);

            var list = await query.ToListAsync();
            var result = list.Select(MapToDto).ToList();

            return new PagedResult<ActivityLogDTO>
            {
                ResultList = result,
                Count = totalCount
            };
        }

        public ActivityLogDTO GetById(Guid id)
        {
            var entity = _context.ActivityLogs
                .Include(al => al.User)
                .FirstOrDefault(al => al.Id == id);

            if (entity == null)
                throw new UserException("Activity log not found.");

            return MapToDto(entity);
        }

        public async Task<List<ActivityLogDTO>> GetByUserAsync(Guid userId, int count = 20)
        {
            var logs = await _context.ActivityLogs
                .Include(al => al.User)
                .Where(al => al.UserId == userId)
                .OrderByDescending(al => al.CreatedAt)
                .Take(count)
                .ToListAsync();

            return logs.Select(MapToDto).ToList();
        }

        public async Task LogActivityAsync(Guid userId, ActivityType activityType, string description, Guid? entityId = null, string? entityType = null, string? ipAddress = null)
        {
            var log = new ActivityLog
            {
                UserId = userId,
                ActivityType = activityType,
                Description = description,
                EntityId = entityId,
                EntityType = entityType,
                IpAddress = ipAddress,
                CreatedAt = DateTime.UtcNow
            };

            _context.ActivityLogs.Add(log);
            await _context.SaveChangesAsync();
        }

        private ActivityLogDTO MapToDto(ActivityLog entity)
        {
            var dto = entity.Adapt<ActivityLogDTO>();
            dto.ActivityType = entity.ActivityType.ToString().ToUpper();

            if (entity.User != null)
                dto.UserName = $"{entity.User.FirstName} {entity.User.LastName}";

            return dto;
        }
    }
}
