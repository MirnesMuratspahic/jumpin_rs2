using System.Text;
using System.Text.Json;
using JumpIn.Models.Messages;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace JumpIn.Worker.Consumers
{
    public class NotificationConsumer : BackgroundService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<NotificationConsumer> _logger;
        private IConnection? _connection;
        private IChannel? _channel;

        public NotificationConsumer(IConfiguration configuration, ILogger<NotificationConsumer> logger)
        {
            _configuration = configuration;
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

            // Retry connection logic
            for (int i = 0; i < 10; i++)
            {
                try
                {
                    _connection = await factory.CreateConnectionAsync(stoppingToken);
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning("RabbitMQ connection attempt {Attempt} failed: {Message}. Retrying in 5s...", i + 1, ex.Message);
                    await Task.Delay(5000, stoppingToken);
                }
            }

            if (_connection == null)
            {
                _logger.LogError("Failed to connect to RabbitMQ after 10 attempts.");
                return;
            }

            _channel = await _connection.CreateChannelAsync(cancellationToken: stoppingToken);
            await _channel.QueueDeclareAsync("notification_queue", durable: true, exclusive: false, autoDelete: false, cancellationToken: stoppingToken);

            var consumer = new AsyncEventingBasicConsumer(_channel);
            consumer.ReceivedAsync += async (model, ea) =>
            {
                try
                {
                    var body = Encoding.UTF8.GetString(ea.Body.ToArray());
                    var message = JsonSerializer.Deserialize<NotificationMessage>(body);

                    if (message != null)
                    {
                        _logger.LogInformation(
                            "[NOTIFICATION] User {UserId} | Type: {Type} | Title: {Title} | Body: {Body}",
                            message.UserId, message.Type, message.Title, message.Body);
                    }

                    await _channel.BasicAckAsync(ea.DeliveryTag, false);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing notification message.");
                    await _channel.BasicNackAsync(ea.DeliveryTag, false, true);
                }
            };

            await _channel.BasicConsumeAsync("notification_queue", autoAck: false, consumer: consumer, cancellationToken: stoppingToken);

            _logger.LogInformation("NotificationConsumer started. Listening on notification_queue...");

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
