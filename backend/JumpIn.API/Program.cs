using System.Text;
using JumpIn.API.Auth;
using JumpIn.API.Filters;
using JumpIn.Services.Database;
using JumpIn.Services.Interfaces;
using JumpIn.Services.Mapping;
using JumpIn.Services.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

// Load secrets/config from a .env file (searched up the directory tree) into
// environment variables BEFORE the host reads configuration. In containers no
// .env exists and values come from docker-compose env instead.
DotNetEnv.Env.TraversePath().Load();

var builder = WebApplication.CreateBuilder(args);

// Register Mapster mappings
RegisterMappings.Register();

// CORS
builder.Services.AddCors(options =>
{
    // Explicit allowed origins (configurable via Cors:AllowedOrigins in .env).
    // The mobile/desktop clients are native apps and aren't subject to CORS;
    // these cover browser-based tooling (Swagger, web dev).
    var allowedOrigins = builder.Configuration["Cors:AllowedOrigins"]
            ?.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
        ?? new[]
        {
            "http://localhost:5194",
            "http://localhost:3000",
            "http://localhost:8080"
        };

    options.AddPolicy("AllowAll", policy =>
    {
        policy.WithOrigins(allowedOrigins)
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Authentication - JWT + Basic Auth
builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme = "Smart";
    options.DefaultChallengeScheme = "Smart";
})
.AddPolicyScheme("Smart", "JWT or Basic", options =>
{
    options.ForwardDefaultSelector = context =>
    {
        var authHeader = context.Request.Headers["Authorization"].FirstOrDefault();
        if (authHeader?.StartsWith("Basic ", StringComparison.OrdinalIgnoreCase) == true)
            return "BasicAuthentication";
        return JwtBearerDefaults.AuthenticationScheme;
    };
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
    };

    // Server-side token revocation: a token is only valid while its security
    // stamp still matches the user's current stamp (logout / password change
    // regenerate the stamp, invalidating previously-issued tokens).
    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = async ctx =>
        {
            var db = ctx.HttpContext.RequestServices.GetRequiredService<JumpInDbContext>();
            var idClaim = ctx.Principal?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (!Guid.TryParse(idClaim, out var uid))
            {
                ctx.Fail("Invalid token.");
                return;
            }

            var user = await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == uid);
            if (user == null || user.IsDeleted)
            {
                ctx.Fail("User no longer exists.");
                return;
            }

            var tokenStamp = ctx.Principal?.FindFirst("sstamp")?.Value;
            if (!string.IsNullOrEmpty(user.SecurityStamp) && user.SecurityStamp != tokenStamp)
                ctx.Fail("Token has been revoked.");
        }
    };
})
.AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("BasicAuthentication", null);

builder.Services.AddAuthorization();

// Controllers with global exception filter
builder.Services.AddControllers(options =>
{
    options.Filters.Add<ExceptionFilter>();
}).AddJsonOptions(options =>
{
    options.JsonSerializerOptions.Converters.Add(
        new System.Text.Json.Serialization.JsonStringEnumConverter());
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter JWT token"
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// Database
builder.Services.AddDbContext<JumpInDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// RabbitMQ
builder.Services.AddSingleton<IMessagePublisher, RabbitMqPublisher>();

// Auth
builder.Services.AddScoped<ITokenService, JwtTokenService>();

// Dependency Injection
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IAdService, AdService>();
builder.Services.AddScoped<IRequestService, RequestService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<ISupportService, SupportService>();
builder.Services.AddScoped<IRecommendationService, RecommendationService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<ISubscriptionService, SubscriptionService>();
builder.Services.AddScoped<IFavoriteService, FavoriteService>();
builder.Services.AddScoped<IAdImageService, AdImageService>();
builder.Services.AddScoped<IUserPreferenceService, UserPreferenceService>();
builder.Services.AddScoped<IActivityLogService, ActivityLogService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IStatisticsService, StatisticsService>();
builder.Services.AddMemoryCache();

var app = builder.Build();

// Database migration and seeding
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var context = services.GetRequiredService<JumpInDbContext>();
    try
    {
        // Apply EF Core migrations so the schema always matches the model and
        // schema changes are tracked. Data is kept across restarts (the seeder
        // below only inserts when the database is empty).
        var db = context.Database;
        if (await db.CanConnectAsync() && !(await db.GetAppliedMigrationsAsync()).Any())
        {
            // A legacy database created via the old EnsureCreated() approach has
            // no migration history; drop it once so it rebuilds from migrations.
            app.Logger.LogInformation("[DB] Legacy database detected; recreating from migrations");
            await db.EnsureDeletedAsync();
        }
        await db.MigrateAsync();
        app.Logger.LogInformation("[DB] Database migrated");
    }
    catch (Exception ex)
    {
        app.Logger.LogError(ex, "[DB] Error initializing database");
    }

    try
    {
        var seeder = new DatabaseSeeder(context, app.Logger);
        await seeder.SeedAsync();
    }
    catch (Exception ex)
    {
        app.Logger.LogError(ex, "[SEED] Error during seeding");
    }
}

// Middleware
app.UseSwagger();
app.UseSwaggerUI();
app.UseHttpsRedirection();
app.UseCors("AllowAll");
app.UseStaticFiles();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.MapGet("/", () => Results.Redirect("/swagger"));

app.Run();
