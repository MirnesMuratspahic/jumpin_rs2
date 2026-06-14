using JumpIn.Models.DTOs;
using JumpIn.Models.Exceptions;
using JumpIn.Models.HelperClasses;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseServices;
using JumpIn.Services.Database;
using JumpIn.Services.Interfaces;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace JumpIn.Services.Services
{
    public class ReviewService : BaseCRUDService<ReviewDTO, ReviewSearchObject, Review, ReviewInsertRequest, ReviewUpdateRequest>, IReviewService
    {
        public ReviewService(JumpInDbContext context) : base(context) { }

        public override async Task<PagedResult<ReviewDTO>> GetPagedAsync(ReviewSearchObject search)
        {
            var query = _context.Reviews
                .Include(r => r.Reviewer)
                .Include(r => r.ReviewedUser)
                .Include(r => r.Ad)
                .AsQueryable();

            query = AddFilter(query, search);
            query = ApplySorting(query, search);

            var totalCount = await query.CountAsync();

            query = query.ApplyPaging(search);

            var list = await query.ToListAsync();
            var result = list.Select(MapToDto).ToList();

            return new PagedResult<ReviewDTO>
            {
                ResultList = result,
                Count = totalCount
            };
        }

        protected override IQueryable<Review> AddFilter(IQueryable<Review> query, ReviewSearchObject search)
        {
            if (search.ReviewerId.HasValue)
                query = query.Where(r => r.ReviewerId == search.ReviewerId.Value);

            if (search.ReviewedUserId.HasValue)
                query = query.Where(r => r.ReviewedUserId == search.ReviewedUserId.Value);

            if (search.MinRating.HasValue)
                query = query.Where(r => r.Rating >= search.MinRating.Value);

            if (search.MaxRating.HasValue)
                query = query.Where(r => r.Rating <= search.MaxRating.Value);

            if (!string.IsNullOrEmpty(search.SearchTerm))
            {
                var term = search.SearchTerm.ToLower();
                query = query.Where(r => r.Comment != null && r.Comment.ToLower().Contains(term));
            }

            return query;
        }

        protected override void BeforeInsert(ReviewInsertRequest request, Review entity)
        {
            if (request.Rating < 1 || request.Rating > 5)
                throw new UserException("Rating must be between 1 and 5.");

            if (request.ReviewerId == entity.ReviewedUserId)
                throw new UserException("You cannot review yourself.");

            var reviewer = _context.Users.Find(request.ReviewerId);
            if (reviewer == null || reviewer.IsDeleted)
                throw new UserException("Reviewer not found.");

            var reviewedUser = _context.Users.Find(entity.ReviewedUserId);
            if (reviewedUser == null || reviewedUser.IsDeleted)
                throw new UserException("Reviewed user not found.");

            entity.CreatedAt = DateTime.UtcNow;
            entity.ReviewerEmail = reviewer.Email;
            entity.ReviewedUserEmail = reviewedUser.Email;
        }

        public List<ReviewDTO> GetReviewsByUser(Guid userId)
        {
            var reviews = _context.Reviews
                .Include(r => r.Reviewer)
                .Include(r => r.ReviewedUser)
                .Include(r => r.Ad)
                .Where(r => r.ReviewedUserId == userId)
                .OrderByDescending(r => r.CreatedAt)
                .ToList();

            return reviews.Select(MapToDto).ToList();
        }

        public ReviewDTO CreateReviewForUser(Guid reviewedUserId, ReviewInsertRequest request)
        {
            var review = new Review
            {
                Rating = request.Rating,
                Comment = request.Comment,
                ReviewerId = request.ReviewerId,
                ReviewedUserId = reviewedUserId,
                AdId = request.AdId
            };

            BeforeInsert(request, review);
            _context.Reviews.Add(review);
            _context.SaveChanges();

            UpdateUserAverageRating(reviewedUserId);

            return MapToDto(review);
        }

        protected override void AfterDelete(Review entity)
        {
            UpdateUserAverageRating(entity.ReviewedUserId);
        }

        private void UpdateUserAverageRating(Guid userId)
        {
            var user = _context.Users.Find(userId);
            if (user != null)
            {
                var reviews = _context.Reviews.Where(r => r.ReviewedUserId == userId).ToList();
                user.AverageRating = reviews.Any() ? (decimal)reviews.Average(r => r.Rating) : 0;
                _context.SaveChanges();
            }
        }

        private ReviewDTO MapToDto(Review entity)
        {
            return new ReviewDTO
            {
                Id = entity.Id,
                Rating = entity.Rating,
                Comment = entity.Comment,
                CreatedAt = entity.CreatedAt,
                ReviewerId = entity.ReviewerId,
                ReviewerName = entity.Reviewer != null ? $"{entity.Reviewer.FirstName} {entity.Reviewer.LastName}" : null,
                ReviewerEmail = entity.ReviewerEmail,
                ReviewerProfileImage = entity.Reviewer?.ProfileImageUrl,
                ReviewedUserId = entity.ReviewedUserId,
                ReviewedUserName = entity.ReviewedUser != null ? $"{entity.ReviewedUser.FirstName} {entity.ReviewedUser.LastName}" : null,
                ReviewedUserEmail = entity.ReviewedUserEmail,
                AdId = entity.AdId,
                AdTitle = entity.Ad?.Title
            };
        }
    }
}
