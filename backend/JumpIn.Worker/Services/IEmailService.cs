using JumpIn.Models.Messages;

namespace JumpIn.Worker.Services
{
    public interface IEmailService
    {
        Task SendEmailAsync(EmailMessage message);
    }
}
