using System.Security.Cryptography;
using JumpIn.Models.DTOs;
using JumpIn.Models.Enums;
using JumpIn.Models.Exceptions;
using JumpIn.Models.Messages;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseServices;
using JumpIn.Services.Database;
using JumpIn.Services.Interfaces;
using Mapster;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace JumpIn.Services.Services
{
    public class UserService : BaseCRUDService<UserModel, UserSearchObject, User, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        private readonly IMessagePublisher _messagePublisher;
        private readonly ILogger<UserService> _logger;

        public UserService(JumpInDbContext context, IMessagePublisher messagePublisher, ILogger<UserService> logger) : base(context)
        {
            _messagePublisher = messagePublisher;
            _logger = logger;
        }

        protected override IQueryable<User> AddFilter(IQueryable<User> query, UserSearchObject search)
        {
            query = query.Where(u => !u.IsDeleted);

            if (!string.IsNullOrEmpty(search.Email))
                query = query.Where(u => u.Email.ToLower().Contains(search.Email.ToLower()));

            if (!string.IsNullOrEmpty(search.Status))
            {
                if (Enum.TryParse<UserStatus>(search.Status, true, out var status))
                    query = query.Where(u => u.Status == status);
            }

            if (!string.IsNullOrEmpty(search.Role))
            {
                if (Enum.TryParse<UserRole>(search.Role, true, out var role))
                    query = query.Where(u => u.Role == role);
            }

            if (search.IsVip.HasValue)
                query = query.Where(u => u.IsVip == search.IsVip.Value);

            return query;
        }

        protected override void BeforeInsert(UserInsertRequest request, User entity)
        {
            if (request.Password != request.PasswordConfirmation)
                throw new UserException("Password and confirmation do not match.");

            var existingEmail = _context.Users.Any(u => u.Email.ToLower() == request.Email.ToLower() && !u.IsDeleted);
            if (existingEmail)
                throw new UserException("A user with this email already exists.");

            entity.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
            entity.SecurityStamp = Guid.NewGuid().ToString("N");
            entity.RegistrationDate = DateTime.UtcNow;
            entity.Status = UserStatus.Active;
            entity.Role = UserRole.Customer;
            entity.IsVip = false;
        }

        protected override void AfterInsert(UserInsertRequest request, User entity)
        {
            // Welcome email is best-effort and async; don't block registration.
            _ = PublishWelcomeEmailAsync(entity.Email, entity.FirstName, entity.Id);
        }

        private async Task PublishWelcomeEmailAsync(string email, string firstName, Guid userId)
        {
            try
            {
                await _messagePublisher.PublishEmailAsync(new EmailMessage
                {
                    To = email,
                    Subject = "Welcome to JumpIn!",
                    Body = $"<h2>Welcome, {firstName}!</h2><p>Your account has been successfully created. Start exploring ads and find what you need!</p>"
                });
            }
            catch (Exception ex)
            {
                // Registration has already succeeded; just log the delivery failure.
                _logger.LogError(ex, "Failed to publish welcome email for user {UserId}.", userId);
            }
        }

        protected override void BeforeUpdate(UserUpdateRequest request, User entity)
        {
            if (!string.IsNullOrEmpty(request.Email) && request.Email.ToLower() != entity.Email.ToLower())
            {
                var existingEmail = _context.Users.Any(u => u.Email.ToLower() == request.Email.ToLower() && u.Id != entity.Id && !u.IsDeleted);
                if (existingEmail)
                    throw new UserException("A user with this email already exists.");
                entity.Email = request.Email;
            }

            if (!string.IsNullOrEmpty(request.Password))
            {
                if (request.Password != request.PasswordConfirmation)
                    throw new UserException("Password and confirmation do not match.");
                entity.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
            }

            if (!string.IsNullOrEmpty(request.FirstName)) entity.FirstName = request.FirstName;
            if (!string.IsNullOrEmpty(request.LastName)) entity.LastName = request.LastName;
            if (request.Phone != null && request.Phone != entity.Phone)
            {
                entity.Phone = request.Phone;
                // Changing the number invalidates any prior verification.
                entity.IsPhoneVerified = false;
                entity.PhoneVerifiedAt = null;
                entity.PhoneVerificationCodeHash = null;
                entity.PhoneVerificationExpiresAt = null;
            }
            if (request.ProfileImageUrl != null) entity.ProfileImageUrl = request.ProfileImageUrl;
        }

        public override UserModel GetById(Guid id)
        {
            var entity = _context.Users.Find(id);
            if (entity == null || entity.IsDeleted)
                throw new UserException("User not found.");

            return entity.Adapt<UserModel>();
        }

        public override UserModel Update(Guid id, UserUpdateRequest request)
        {
            var entity = _context.Users.Find(id);
            if (entity == null || entity.IsDeleted)
                throw new UserException("User not found.");

            BeforeUpdate(request, entity);
            _context.SaveChanges();

            return entity.Adapt<UserModel>();
        }

        public async Task<UserModel> LoginAsync(LoginRequest request)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u =>
                    u.Email.ToLower() == request.Email.ToLower() &&
                    !u.IsDeleted);

            if (user == null)
                throw new UserException("Invalid email or password.");

            if (user.Status == UserStatus.Blocked)
                throw new UserException($"Your account has been blocked. Reason: {user.BlockReason ?? "No reason provided."}");

            if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                throw new UserException("Invalid email or password.");

            // Ensure a security stamp exists (e.g. for seeded users) so the
            // issued token can be validated/revoked server-side.
            if (string.IsNullOrEmpty(user.SecurityStamp))
                user.SecurityStamp = Guid.NewGuid().ToString("N");

            user.LastLogin = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return user.Adapt<UserModel>();
        }

        public async Task LogoutAsync(Guid id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null || user.IsDeleted)
                throw new UserException("User not found.");

            // Regenerate the stamp → all previously-issued tokens are now invalid.
            user.SecurityStamp = Guid.NewGuid().ToString("N");
            await _context.SaveChangesAsync();
        }

        public async Task ChangePasswordAsync(Guid id, ChangePasswordRequest request, bool requireCurrentPassword)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null || user.IsDeleted)
                throw new UserException("User not found.");

            if (string.IsNullOrWhiteSpace(request.NewPassword) || request.NewPassword.Length < 6)
                throw new UserException("New password must be at least 6 characters.");

            if (request.NewPassword != request.ConfirmNewPassword)
                throw new UserException("New password and confirmation do not match.");

            if (requireCurrentPassword)
            {
                if (string.IsNullOrEmpty(request.CurrentPassword) ||
                    !BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
                    throw new UserException("Current password is incorrect.");
            }

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            // Changing the password invalidates existing sessions.
            user.SecurityStamp = Guid.NewGuid().ToString("N");
            await _context.SaveChangesAsync();
        }

        public async Task RequestPasswordResetAsync(string email)
        {
            var user = await _context.Users.FirstOrDefaultAsync(
                u => u.Email.ToLower() == email.ToLower() && !u.IsDeleted);

            // Don't reveal whether the email exists.
            if (user == null) return;

            // Cryptographically-secure 6-digit code; only its hash is stored.
            var code = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
            user.ResetPasswordCodeHash = BCrypt.Net.BCrypt.HashPassword(code);
            user.ResetPasswordExpiresAt = DateTime.UtcNow.AddMinutes(15);
            await _context.SaveChangesAsync();

            try
            {
                await _messagePublisher.PublishEmailAsync(new EmailMessage
                {
                    To = user.Email,
                    Subject = "JumpIn password reset code",
                    Body = $"<h2>Password reset</h2><p>Your password reset code is <strong>{code}</strong>. It expires in 15 minutes.</p><p>If you didn't request this, you can safely ignore this email.</p>"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send password reset email for user {UserId}.", user.Id);
            }
        }

        public async Task ResetPasswordAsync(ResetPasswordRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(
                u => u.Email.ToLower() == request.Email.ToLower() && !u.IsDeleted);

            if (user == null ||
                string.IsNullOrEmpty(user.ResetPasswordCodeHash) ||
                user.ResetPasswordExpiresAt == null)
                throw new UserException("Invalid or expired reset code.");

            if (user.ResetPasswordExpiresAt < DateTime.UtcNow)
                throw new UserException("The reset code has expired. Please request a new one.");

            if (string.IsNullOrEmpty(request.Code) ||
                !BCrypt.Net.BCrypt.Verify(request.Code, user.ResetPasswordCodeHash))
                throw new UserException("Invalid or expired reset code.");

            if (string.IsNullOrWhiteSpace(request.NewPassword) || request.NewPassword.Length < 6)
                throw new UserException("New password must be at least 6 characters.");

            if (request.NewPassword != request.ConfirmNewPassword)
                throw new UserException("New password and confirmation do not match.");

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            user.ResetPasswordCodeHash = null;
            user.ResetPasswordExpiresAt = null;
            // Reset invalidates existing sessions.
            user.SecurityStamp = Guid.NewGuid().ToString("N");
            await _context.SaveChangesAsync();
        }

        public async Task SendPhoneVerificationCodeAsync(Guid id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null || user.IsDeleted)
                throw new UserException("User not found.");

            if (string.IsNullOrWhiteSpace(user.Phone))
                throw new UserException("Add a phone number to your profile before verifying it.");

            if (user.IsPhoneVerified)
                throw new UserException("Your phone number is already verified.");

            // Cryptographically-secure 6-digit code; only its hash is stored.
            var code = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
            user.PhoneVerificationCodeHash = BCrypt.Net.BCrypt.HashPassword(code);
            user.PhoneVerificationExpiresAt = DateTime.UtcNow.AddMinutes(15);
            await _context.SaveChangesAsync();

            // Sandbox delivery (acceptable for the project): log the code server-side
            // and also email it to the user so the flow is demonstrable end-to-end.
            // A real deployment would send this via an SMS gateway.
            _logger.LogInformation("[SANDBOX SMS] Phone verification code for {Phone}: {Code}", user.Phone, code);
            try
            {
                await _messagePublisher.PublishEmailAsync(new EmailMessage
                {
                    To = user.Email,
                    Subject = "JumpIn phone verification code",
                    Body = $"<h2>Phone verification</h2><p>Your phone verification code is <strong>{code}</strong>. It expires in 15 minutes.</p>"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send phone verification code for user {UserId}.", user.Id);
            }
        }

        public async Task<UserModel> VerifyPhoneAsync(Guid id, string? code)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null || user.IsDeleted)
                throw new UserException("User not found.");

            if (user.IsPhoneVerified)
                return user.Adapt<UserModel>();

            if (string.IsNullOrEmpty(user.PhoneVerificationCodeHash) ||
                user.PhoneVerificationExpiresAt == null)
                throw new UserException("Request a verification code first.");

            if (user.PhoneVerificationExpiresAt < DateTime.UtcNow)
                throw new UserException("The verification code has expired. Please request a new one.");

            if (string.IsNullOrEmpty(code) ||
                !BCrypt.Net.BCrypt.Verify(code, user.PhoneVerificationCodeHash))
                throw new UserException("Invalid verification code.");

            user.IsPhoneVerified = true;
            user.PhoneVerifiedAt = DateTime.UtcNow;
            user.PhoneVerificationCodeHash = null;
            user.PhoneVerificationExpiresAt = null;
            await _context.SaveChangesAsync();

            return user.Adapt<UserModel>();
        }

        public async Task<UserModel> BlockUserAsync(Guid id, BlockUserRequest request)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null || user.IsDeleted)
                throw new UserException("User not found.");

            user.Status = UserStatus.Blocked;
            user.BlockReason = request.Reason;
            user.BlockedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return user.Adapt<UserModel>();
        }

        public async Task<UserModel> UnblockUserAsync(Guid id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null || user.IsDeleted)
                throw new UserException("User not found.");

            user.Status = UserStatus.Active;
            user.BlockReason = null;
            user.BlockedAt = null;
            await _context.SaveChangesAsync();

            return user.Adapt<UserModel>();
        }

        public async Task<UserStatistics> GetUserStatisticsAsync(Guid id)
        {
            var user = await _context.Users
                .Include(u => u.Ads)
                .Include(u => u.SentRequests)
                .Include(u => u.ReceivedRequests)
                .Include(u => u.ReviewsGiven)
                .Include(u => u.ReviewsReceived)
                .FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted);

            if (user == null)
                throw new UserException("User not found.");

            return new UserStatistics
            {
                TotalAds = user.TotalAds,
                ActiveAds = user.Ads.Count(a => !a.IsDeleted && a.IsActive),
                TotalRequestsSent = user.SentRequests.Count(r => !r.IsDeleted),
                TotalRequestsReceived = user.ReceivedRequests.Count(r => !r.IsDeleted),
                AcceptedRequests = user.ReceivedRequests.Count(r => !r.IsDeleted && r.Status == RequestStatus.Accepted),
                DeclinedRequests = user.ReceivedRequests.Count(r => !r.IsDeleted && r.Status == RequestStatus.Declined),
                TotalReviewsGiven = user.ReviewsGiven.Count,
                TotalReviewsReceived = user.ReviewsReceived.Count,
                AverageRating = user.AverageRating,
                IsVip = user.IsVip
            };
        }
    }
}
