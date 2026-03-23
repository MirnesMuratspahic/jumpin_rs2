using JumpIn.Models.Messages;

namespace JumpIn.Services.Interfaces
{
    public interface IMessagePublisher
    {
        void PublishEmail(EmailMessage message);
        void PublishNotification(NotificationMessage message);
    }
}
