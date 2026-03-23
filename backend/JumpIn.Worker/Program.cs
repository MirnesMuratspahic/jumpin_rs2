using JumpIn.Worker.Consumers;
using JumpIn.Worker.Services;

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddSingleton<IEmailService, EmailService>();
builder.Services.AddHostedService<EmailConsumer>();
builder.Services.AddHostedService<NotificationConsumer>();

var host = builder.Build();
host.Run();
