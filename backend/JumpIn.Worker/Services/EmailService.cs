using JumpIn.Models.Messages;
using MailKit.Net.Smtp;
using MimeKit;

namespace JumpIn.Worker.Services
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task SendEmailAsync(EmailMessage message)
        {
            var smtpHost = _configuration["Smtp:Host"];
            var smtpPort = int.Parse(_configuration["Smtp:Port"] ?? "587");
            var smtpUsername = _configuration["Smtp:Username"];
            var smtpPassword = _configuration["Smtp:Password"];
            var useSsl = bool.Parse(_configuration["Smtp:UseSsl"] ?? "true");
            var senderEmail = _configuration["Smtp:SenderEmail"] ?? "jumpin@example.com";
            var senderName = _configuration["Smtp:SenderName"] ?? "JumpIn";

            if (string.IsNullOrEmpty(smtpHost) || string.IsNullOrEmpty(smtpUsername))
            {
                _logger.LogWarning("SMTP not configured. Email to {To} with subject '{Subject}' was not sent.", message.To, message.Subject);
                _logger.LogInformation("Email content: {Body}", message.Body);
                return;
            }

            var email = new MimeMessage();
            email.From.Add(new MailboxAddress(senderName, senderEmail));
            email.To.Add(MailboxAddress.Parse(message.To));
            email.Subject = message.Subject;
            email.Body = new TextPart("html") { Text = message.Body };

            using var client = new SmtpClient();
            await client.ConnectAsync(smtpHost, smtpPort, useSsl);
            await client.AuthenticateAsync(smtpUsername, smtpPassword);
            await client.SendAsync(email);
            await client.DisconnectAsync(true);

            _logger.LogInformation("Email sent to {To} with subject '{Subject}'.", message.To, message.Subject);
        }
    }
}
