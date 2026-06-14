using JumpIn.Models.DTOs;
using JumpIn.Models.Exceptions;
using JumpIn.Models.HelperClasses;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.Database;
using JumpIn.Services.Interfaces;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace JumpIn.Services.Services
{
    public class NotificationService : INotificationService
    {
        private readonly JumpInDbContext _context;

        public NotificationService(JumpInDbContext context)
        {
            _context = context;
        }

        public async Task<PagedResult<NotificationDTO>> GetPagedAsync(NotificationSearchObject search)
        {
            var query = _context.Notifications.AsQueryable();

            if (search.UserId.HasValue)
                query = query.Where(n => n.UserId == search.UserId.Value);

            if (search.IsRead.HasValue)
                query = query.Where(n => n.IsRead == search.IsRead.Value);

            query = query.OrderByDescending(n => n.CreatedAt);

            var totalCount = await query.CountAsync();

            var page = search.Page ?? 1;
            var pageSize = Math.Clamp(search.PageSize ?? 20, 1, 100);
            query = query.Skip((page - 1) * pageSize).Take(pageSize);

            var list = await query.ToListAsync();

            return new PagedResult<NotificationDTO>
            {
                ResultList = list.Select(n => n.Adapt<NotificationDTO>()).ToList(),
                Count = totalCount
            };
        }

        public async Task<int> GetUnreadCountAsync(Guid userId)
        {
            return await _context.Notifications
                .CountAsync(n => n.UserId == userId && !n.IsRead);
        }

        public async Task<NotificationDTO> MarkReadAsync(Guid id, Guid userId)
        {
            var entity = await _context.Notifications.FirstOrDefaultAsync(n => n.Id == id);
            if (entity == null)
                throw new UserException("Notification not found.");
            if (entity.UserId != userId)
                throw new ForbiddenException();

            if (!entity.IsRead)
            {
                entity.IsRead = true;
                entity.ReadAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }

            return entity.Adapt<NotificationDTO>();
        }

        public async Task MarkAllReadAsync(Guid userId)
        {
            var unread = await _context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .ToListAsync();

            if (unread.Count == 0) return;

            var now = DateTime.UtcNow;
            foreach (var n in unread)
            {
                n.IsRead = true;
                n.ReadAt = now;
            }
            await _context.SaveChangesAsync();
        }

        public async Task CreateAsync(Guid userId, string title, string message, string type)
        {
            _context.Notifications.Add(BuildNotification(userId, title, message, type));
            await _context.SaveChangesAsync();
        }

        public void Create(Guid userId, string title, string message, string type)
        {
            _context.Notifications.Add(BuildNotification(userId, title, message, type));
            _context.SaveChanges();
        }

        private static Notification BuildNotification(Guid userId, string title, string message, string type)
            => new Notification
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Title = title,
                Message = message,
                Type = type,
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };
    }
}
