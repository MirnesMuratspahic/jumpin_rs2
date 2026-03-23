using System.Text;
using System.Text.Json;
using JumpIn.Models.Messages;
using JumpIn.Services.Interfaces;
using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;

namespace JumpIn.Services.Services
{
    public class RabbitMqPublisher : IMessagePublisher, IDisposable
    {
        private readonly IConnection _connection;
        private readonly IChannel _channel;

        public RabbitMqPublisher(IConfiguration configuration)
        {
            var factory = new ConnectionFactory
            {
                HostName = configuration["RabbitMQ:Host"] ?? "localhost",
                Port = int.Parse(configuration["RabbitMQ:Port"] ?? "5672"),
                UserName = configuration["RabbitMQ:Username"] ?? "guest",
                Password = configuration["RabbitMQ:Password"] ?? "guest"
            };

            _connection = factory.CreateConnectionAsync().GetAwaiter().GetResult();
            _channel = _connection.CreateChannelAsync().GetAwaiter().GetResult();

            _channel.QueueDeclareAsync("email_queue", durable: true, exclusive: false, autoDelete: false).GetAwaiter().GetResult();
            _channel.QueueDeclareAsync("notification_queue", durable: true, exclusive: false, autoDelete: false).GetAwaiter().GetResult();
        }

        public void PublishEmail(EmailMessage message)
        {
            Publish("email_queue", message);
        }

        public void PublishNotification(NotificationMessage message)
        {
            Publish("notification_queue", message);
        }

        private void Publish<T>(string queue, T message)
        {
            var json = JsonSerializer.Serialize(message);
            var body = Encoding.UTF8.GetBytes(json);

            var properties = new BasicProperties
            {
                Persistent = true
            };

            _channel.BasicPublishAsync(
                exchange: "",
                routingKey: queue,
                mandatory: false,
                basicProperties: properties,
                body: body).GetAwaiter().GetResult();
        }

        public void Dispose()
        {
            _channel?.Dispose();
            _connection?.Dispose();
        }
    }
}
