using System.Text;
using System.Text.Json;
using JumpIn.Models.Messages;
using JumpIn.Services.Interfaces;
using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;

namespace JumpIn.Services.Services
{
    public class RabbitMqPublisher : IMessagePublisher, IAsyncDisposable
    {
        private readonly ConnectionFactory _factory;
        private readonly SemaphoreSlim _initLock = new(1, 1);
        private IConnection? _connection;
        private IChannel? _channel;

        public RabbitMqPublisher(IConfiguration configuration)
        {
            // No blocking connect in the constructor; the connection is created
            // lazily and asynchronously on the first publish.
            _factory = new ConnectionFactory
            {
                HostName = configuration["RabbitMQ:Host"] ?? "localhost",
                Port = int.Parse(configuration["RabbitMQ:Port"] ?? "5672"),
                UserName = configuration["RabbitMQ:Username"] ?? "guest",
                Password = configuration["RabbitMQ:Password"] ?? "guest"
            };
        }

        public Task PublishEmailAsync(EmailMessage message) =>
            PublishAsync("email_queue", message);

        public Task PublishNotificationAsync(NotificationMessage message) =>
            PublishAsync("notification_queue", message);

        private async Task EnsureChannelAsync()
        {
            if (_channel is { IsOpen: true }) return;

            await _initLock.WaitAsync();
            try
            {
                if (_channel is { IsOpen: true }) return;

                _connection ??= await _factory.CreateConnectionAsync();
                _channel = await _connection.CreateChannelAsync();

                await _channel.QueueDeclareAsync("email_queue", durable: true, exclusive: false, autoDelete: false);
                await _channel.QueueDeclareAsync("notification_queue", durable: true, exclusive: false, autoDelete: false);
            }
            finally
            {
                _initLock.Release();
            }
        }

        private async Task PublishAsync<T>(string queue, T message)
        {
            await EnsureChannelAsync();

            var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(message));
            var properties = new BasicProperties { Persistent = true };

            await _channel!.BasicPublishAsync(
                exchange: "",
                routingKey: queue,
                mandatory: false,
                basicProperties: properties,
                body: body);
        }

        public async ValueTask DisposeAsync()
        {
            if (_channel != null) await _channel.DisposeAsync();
            if (_connection != null) await _connection.DisposeAsync();
            _initLock.Dispose();
        }
    }
}
