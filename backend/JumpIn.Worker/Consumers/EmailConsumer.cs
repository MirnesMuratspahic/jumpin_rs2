using System.Text;
using System.Text.Json;
using JumpIn.Models.Messages;
using JumpIn.Worker.Services;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace JumpIn.Worker.Consumers
{
    public class EmailConsumer : BackgroundService
    {
        private readonly IConfiguration _configuration;
        private readonly IEmailService _emailService;
        private readonly ILogger<EmailConsumer> _logger;
        private IConnection? _connection;
        private IChannel? _channel;

        public EmailConsumer(IConfiguration configuration, IEmailService emailService, ILogger<EmailConsumer> logger)
        {
            _configuration = configuration;
            _emailService = emailService;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            var factory = new ConnectionFactory
            {
                HostName = _configuration["RabbitMQ:Host"] ?? "localhost",
                Port = int.Parse(_configuration["RabbitMQ:Port"] ?? "5672"),
                UserName = _configuration["RabbitMQ:Username"] ?? "guest",
                Password = _configuration["RabbitMQ:Password"] ?? "guest"
            };

            // Retry connection with exponential backoff (1s, 2s, 4s, 8s ... capped at 30s).
            for (int i = 0; i < 10; i++)
            {
                try
                {
                    _connection = await factory.CreateConnectionAsync(stoppingToken);
                    break;
                }
                catch (Exception ex)
                {
                    var delaySeconds = Math.Min(30, (int)Math.Pow(2, i));
                    _logger.LogWarning("RabbitMQ connection attempt {Attempt} failed: {Message}. Retrying in {Delay}s...", i + 1, ex.Message, delaySeconds);
                    await Task.Delay(TimeSpan.FromSeconds(delaySeconds), stoppingToken);
                }
            }

            if (_connection == null)
            {
                _logger.LogError("Failed to connect to RabbitMQ after 10 attempts.");
                return;
            }

            _channel = await _connection.CreateChannelAsync(cancellationToken: stoppingToken);
            await _channel.QueueDeclareAsync("email_queue", durable: true, exclusive: false, autoDelete: false, cancellationToken: stoppingToken);

            var consumer = new AsyncEventingBasicConsumer(_channel);
            consumer.ReceivedAsync += async (model, ea) =>
            {
                try
                {
                    var body = Encoding.UTF8.GetString(ea.Body.ToArray());
                    var message = JsonSerializer.Deserialize<EmailMessage>(body);

                    if (message != null)
                    {
                        _logger.LogInformation("Processing email to {To}...", message.To);
                        await _emailService.SendEmailAsync(message);
                    }

                    await _channel.BasicAckAsync(ea.DeliveryTag, false);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing email message.");
                    await _channel.BasicNackAsync(ea.DeliveryTag, false, true);
                }
            };

            await _channel.BasicConsumeAsync("email_queue", autoAck: false, consumer: consumer, cancellationToken: stoppingToken);

            _logger.LogInformation("EmailConsumer started. Listening on email_queue...");

            await Task.Delay(Timeout.Infinite, stoppingToken);
        }

        public override void Dispose()
        {
            _channel?.Dispose();
            _connection?.Dispose();
            base.Dispose();
        }
    }
}
