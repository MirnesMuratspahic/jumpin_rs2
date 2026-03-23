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

namespace JumpIn.Services.Services
{
    public class UserService : BaseCRUDService<UserModel, UserSearchObject, User, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        private readonly IMessagePublisher _messagePublisher;

        public UserService(JumpInDbContext context, IMessagePublisher messagePublisher) : base(context)
        {
            _messagePublisher = messagePublisher;
        }

        protected override IQueryable<User> AddFilter(IQueryable<User> query, UserSearchObject search)
        {
            query = query.Where(u => !u.IsDeleted);

            if (!string.IsNullOrEmpty(search.Username))
                query = query.Where(u => u.Username.ToLower().Contains(search.Username.ToLower()));

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

            var existingUsername = _context.Users.Any(u => u.Username.ToLower() == request.Username.ToLower() && !u.IsDeleted);
            if (existingUsername)
                throw new UserException("A user with this username already exists.");

            entity.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
            entity.RegistrationDate = DateTime.UtcNow;
            entity.Status = UserStatus.Active;
            entity.Role = UserRole.Customer;
            entity.IsVip = false;
        }

        protected override void AfterInsert(UserInsertRequest request, User entity)
        {
            try
            {
                _messagePublisher.PublishEmail(new EmailMessage
                {
                    To = entity.Email,
                    Subject = "Welcome to JumpIn!",
                    Body = $"<h2>Welcome, {entity.FirstName}!</h2><p>Your account has been successfully created. Start exploring ads and find what you need!</p>"
                });
            }
            catch { }
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

            if (!string.IsNullOrEmpty(request.Username) && request.Username.ToLower() != entity.Username.ToLower())
            {
                var existingUsername = _context.Users.Any(u => u.Username.ToLower() == request.Username.ToLower() && u.Id != entity.Id && !u.IsDeleted);
                if (existingUsername)
                    throw new UserException("A user with this username already exists.");
                entity.Username = request.Username;
            }

            if (!string.IsNullOrEmpty(request.Password))
            {
                if (request.Password != request.PasswordConfirmation)
                    throw new UserException("Password and confirmation do not match.");
                entity.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
            }

            if (!string.IsNullOrEmpty(request.FirstName)) entity.FirstName = request.FirstName;
            if (!string.IsNullOrEmpty(request.LastName)) entity.LastName = request.LastName;
            if (request.Phone != null) entity.Phone = request.Phone;
            if (request.ProfileImageUrl != null) entity.ProfileImageUrl = request.ProfileImageUrl;
        }

        public override UserModel Update(int id, UserUpdateRequest request)
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
                    (u.Username.ToLower() == request.Username.ToLower() ||
                     u.Email.ToLower() == request.Username.ToLower()) &&
                    !u.IsDeleted);

            if (user == null)
                throw new UserException("Invalid username or password.");

            if (user.Status == UserStatus.Blocked)
                throw new UserException($"Your account has been blocked. Reason: {user.BlockReason ?? "No reason provided."}");

            if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                throw new UserException("Invalid username or password.");

            user.LastLogin = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return user.Adapt<UserModel>();
        }

        public async Task<UserModel> BlockUserAsync(int id, BlockUserRequest request)
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

        public async Task<UserModel> UnblockUserAsync(int id)
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

        public async Task<UserModel> ActivateVipAsync(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null || user.IsDeleted)
                throw new UserException("User not found.");

            user.IsVip = true;
            user.VipActivatedAt = DateTime.UtcNow;
            user.VipExpiresAt = DateTime.UtcNow.AddMonths(1);
            await _context.SaveChangesAsync();

            return user.Adapt<UserModel>();
        }

        public async Task<UserStatistics> GetUserStatisticsAsync(int id)
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
                TotalAds = user.Ads.Count(a => !a.IsDeleted),
                ActiveAds = user.Ads.Count(a => !a.IsDeleted && a.IsActive),
                TotalRequestsSent = user.SentRequests.Count(r => !r.IsDeleted),
                TotalRequestsReceived = user.ReceivedRequests.Count(r => !r.IsDeleted),
                AcceptedRequests = user.ReceivedRequests.Count(r => !r.IsDeleted && r.Status == RequestStatus.Accepted),
                DeclinedRequests = user.ReceivedRequests.Count(r => !r.IsDeleted && r.Status == RequestStatus.Declined),
                TotalReviewsGiven = user.ReviewsGiven.Count,
                TotalReviewsReceived = user.ReviewsReceived.Count,
                AverageRating = user.ReviewsReceived.Any() ? (decimal)user.ReviewsReceived.Average(r => r.Rating) : 0,
                IsVip = user.IsVip
            };
        }
    }
}
