using JumpIn.Models.DTOs;
using JumpIn.Models.Enums;
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
    public class AdService : BaseCRUDService<AdDTO, AdSearchObject, Ad, AdInsertRequest, AdUpdateRequest>, IAdService
    {
        public AdService(JumpInDbContext context) : base(context) { }

        public override async Task<PagedResult<AdDTO>> GetPagedAsync(AdSearchObject search)
        {
            var query = _context.Ads
                .Include(a => a.User)
                .Include(a => a.AdImages)
                .Where(a => !a.IsDeleted)
                .AsQueryable();

            query = AddFilter(query, search);
            query = ApplySorting(query, search);

            var totalCount = await query.CountAsync();

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value)
                             .Take(search.PageSize.Value);
            }

            var list = await query.ToListAsync();
            var result = list.Select(MapToDto).ToList();

            return new PagedResult<AdDTO>
            {
                ResultList = result,
                Count = totalCount
            };
        }

        public override AdDTO GetById(Guid id)
        {
            var entity = _context.Ads
                .Include(a => a.User)
                .Include(a => a.AdImages)
                .FirstOrDefault(a => a.Id == id && !a.IsDeleted);

            if (entity == null)
                throw new UserException("Ad not found.");

            return MapToDto(entity);
        }

        protected override IQueryable<Ad> AddFilter(IQueryable<Ad> query, AdSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.SearchTerm))
            {
                var term = search.SearchTerm.ToLower();
                query = query.Where(a =>
                    a.Title.ToLower().Contains(term) ||
                    (a.Description != null && a.Description.ToLower().Contains(term)) ||
                    (a.Location != null && a.Location.ToLower().Contains(term)) ||
                    (a.LocationFrom != null && a.LocationFrom.ToLower().Contains(term)) ||
                    (a.LocationTo != null && a.LocationTo.ToLower().Contains(term)));
            }

            if (!string.IsNullOrEmpty(search.AdType))
            {
                if (Enum.TryParse<AdType>(search.AdType, true, out var adType))
                    query = query.Where(a => a.AdType == adType);
            }

            if (search.MinPrice.HasValue)
                query = query.Where(a => a.Price >= search.MinPrice.Value);

            if (search.MaxPrice.HasValue)
                query = query.Where(a => a.Price <= search.MaxPrice.Value);

            if (!string.IsNullOrEmpty(search.Location))
            {
                var loc = search.Location.ToLower();
                query = query.Where(a =>
                    (a.Location != null && a.Location.ToLower().Contains(loc)) ||
                    (a.LocationFrom != null && a.LocationFrom.ToLower().Contains(loc)) ||
                    (a.LocationTo != null && a.LocationTo.ToLower().Contains(loc)));
            }

            if (search.UserId.HasValue)
                query = query.Where(a => a.UserId == search.UserId.Value);

            if (search.IsActive.HasValue)
                query = query.Where(a => a.IsActive == search.IsActive.Value);

            if (search.IsVipOwner.HasValue)
                query = query.Where(a => a.User.IsVip == search.IsVipOwner.Value);

            return query;
        }

        protected override void BeforeInsert(AdInsertRequest request, Ad entity)
        {
            var user = _context.Users.Find(request.UserId);
            if (user == null || user.IsDeleted)
                throw new UserException("User not found.");

            entity.CreatedAt = DateTime.UtcNow;
            entity.IsActive = true;
        }

        protected override void AfterInsert(AdInsertRequest request, Ad entity)
        {
            var user = _context.Users.Find(request.UserId);
            if (user != null)
            {
                user.TotalAds++;
                _context.SaveChanges();
            }
        }

        protected override void BeforeDelete(Ad entity)
        {
            var user = _context.Users.Find(entity.UserId);
            if (user != null && user.TotalAds > 0)
            {
                user.TotalAds--;
                _context.SaveChanges();
            }
        }

        public async Task<AdDTO> EndAdAsync(Guid id, Guid? userId = null)
        {
            var entity = _context.Ads
                .Include(a => a.User)
                .Include(a => a.AdImages)
                .FirstOrDefault(a => a.Id == id && !a.IsDeleted);

            if (entity == null)
                throw new UserException("Ad not found.");

            if (userId.HasValue && entity.UserId != userId.Value)
                throw new UserException("You can only end your own ads.");

            entity.Status = AdStatus.Ended;
            entity.IsActive = false;
            _context.SaveChanges();

            return MapToDto(entity);
        }

        private AdDTO MapToDto(Ad entity)
        {
            var dto = entity.Adapt<AdDTO>();
            dto.Type = entity.AdType.ToString().ToUpper();
            dto.Status = entity.Status?.ToString() ?? "Active";

            if (entity.User != null)
            {
                dto.OwnerUsername = entity.User.Email;
                dto.UserProfileImage = entity.User.ProfileImageUrl;
                dto.IsVipOwner = entity.User.IsVip;
                dto.UserRating = entity.User.AverageRating;
            }

            if (entity.AdImages != null && entity.AdImages.Any())
            {
                dto.Images = entity.AdImages
                    .OrderBy(i => i.DisplayOrder)
                    .Select(i => i.Adapt<AdImageDTO>())
                    .ToList();

                var mainImage = entity.AdImages.FirstOrDefault(i => i.IsMainImage);
                if (mainImage != null)
                    dto.ImageUrl = mainImage.ImageUrl;
            }

            return dto;
        }
    }
}
