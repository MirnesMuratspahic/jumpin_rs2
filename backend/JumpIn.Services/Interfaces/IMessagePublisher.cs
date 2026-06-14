using JumpIn.Models.Messages;

namespace JumpIn.Services.Interfaces
{
    public interface IMessagePublisher
    {
        Task PublishEmailAsync(EmailMessage message);
        Task PublishNotificationAsync(NotificationMessage message);
    }
}
