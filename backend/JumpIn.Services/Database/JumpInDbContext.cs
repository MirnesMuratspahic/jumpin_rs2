using Microsoft.EntityFrameworkCore;

namespace JumpIn.Services.Database
{
    public class JumpInDbContext : DbContext
    {
        public JumpInDbContext(DbContextOptions<JumpInDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Ad> Ads { get; set; }
        public DbSet<Request> Requests { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<SupportMessage> SupportMessages { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<Favorite> Favorites { get; set; }
        public DbSet<AdImage> AdImages { get; set; }
        public DbSet<UserPreference> UserPreferences { get; set; }
        public DbSet<ActivityLog> ActivityLogs { get; set; }
        public DbSet<City> Cities { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // User
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasIndex(u => u.Username).IsUnique();
                entity.HasIndex(u => u.Email).IsUnique();
            });

            // Ad
            modelBuilder.Entity<Ad>(entity =>
            {
                entity.HasOne(a => a.User)
                    .WithMany(u => u.Ads)
                    .HasForeignKey(a => a.UserId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Request
            modelBuilder.Entity<Request>(entity =>
            {
                entity.HasIndex(r => r.RequestNumber).IsUnique();

                entity.HasOne(r => r.Sender)
                    .WithMany(u => u.SentRequests)
                    .HasForeignKey(r => r.SenderId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(r => r.Receiver)
                    .WithMany(u => u.ReceivedRequests)
                    .HasForeignKey(r => r.ReceiverId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(r => r.Ad)
                    .WithMany(a => a.Requests)
                    .HasForeignKey(r => r.AdId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Review
            modelBuilder.Entity<Review>(entity =>
            {
                entity.HasOne(r => r.Reviewer)
                    .WithMany(u => u.ReviewsGiven)
                    .HasForeignKey(r => r.ReviewerId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(r => r.ReviewedUser)
                    .WithMany(u => u.ReviewsReceived)
                    .HasForeignKey(r => r.ReviewedUserId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(r => r.Ad)
                    .WithMany(a => a.Reviews)
                    .HasForeignKey(r => r.AdId)
                    .IsRequired(false)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // SupportMessage
            modelBuilder.Entity<SupportMessage>(entity =>
            {
                entity.HasOne(s => s.User)
                    .WithMany(u => u.SupportMessages)
                    .HasForeignKey(s => s.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Payment
            modelBuilder.Entity<Payment>(entity =>
            {
                entity.HasOne(p => p.User)
                    .WithMany(u => u.Payments)
                    .HasForeignKey(p => p.UserId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Favorite
            modelBuilder.Entity<Favorite>(entity =>
            {
                entity.HasIndex(f => new { f.UserId, f.AdId }).IsUnique();

                entity.HasOne(f => f.User)
                    .WithMany(u => u.Favorites)
                    .HasForeignKey(f => f.UserId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(f => f.Ad)
                    .WithMany(a => a.Favorites)
                    .HasForeignKey(f => f.AdId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // AdImage
            modelBuilder.Entity<AdImage>(entity =>
            {
                entity.HasOne(ai => ai.Ad)
                    .WithMany(a => a.AdImages)
                    .HasForeignKey(ai => ai.AdId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // UserPreference
            modelBuilder.Entity<UserPreference>(entity =>
            {
                entity.HasIndex(up => up.UserId).IsUnique();

                entity.HasOne(up => up.User)
                    .WithMany(u => u.UserPreferences)
                    .HasForeignKey(up => up.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // ActivityLog
            modelBuilder.Entity<ActivityLog>(entity =>
            {
                entity.HasOne(al => al.User)
                    .WithMany(u => u.ActivityLogs)
                    .HasForeignKey(al => al.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}
