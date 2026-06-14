using JumpIn.Models.DTOs;
using JumpIn.Models.HelperClasses;
using JumpIn.Models.SearchObjects;

namespace JumpIn.Services.Interfaces
{
    public interface INotificationService
    {
        Task<PagedResult<NotificationDTO>> GetPagedAsync(NotificationSearchObject search);
        Task<int> GetUnreadCountAsync(Guid userId);
        Task<NotificationDTO> MarkReadAsync(Guid id, Guid userId);
        Task MarkAllReadAsync(Guid userId);

        // Persists a notification for a user. Used by other services on domain events.
        Task CreateAsync(Guid userId, string title, string message, string type);
        void Create(Guid userId, string title, string message, string type);
    }
}
