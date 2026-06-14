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

        // Insert saves the ad and then bumps the owner's TotalAds (two SaveChanges);
        // wrap them in one transaction so they commit atomically.
        public override AdDTO Insert(AdInsertRequest request)
        {
            using var tx = _context.Database.BeginTransaction();
            var result = base.Insert(request);
            tx.Commit();
            return result;
        }

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

            query = query.ApplyPaging(search);

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

            // The client hides past slots, but the rule must also hold server-side
            // since the API can be called directly.
            if (request.DateAvailable.HasValue &&
                request.DateAvailable.Value.Date < DateTime.UtcNow.Date)
                throw new UserException("The availability date cannot be in the past.");

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

        public async Task<AdDTO> EndAdAsync(Guid id, Guid? ownerCheckUserId = null, Guid? actorUserId = null)
        {
            var entity = await _context.Ads
                .Include(a => a.User)
                .Include(a => a.AdImages)
                .FirstOrDefaultAsync(a => a.Id == id && !a.IsDeleted);

            if (entity == null)
                throw new UserException("Ad not found.");

            if (ownerCheckUserId.HasValue && entity.UserId != ownerCheckUserId.Value)
                throw new UserException("You can only end your own ads.");

            entity.Status = AdStatus.Ended;
            entity.IsActive = false;
            entity.EndedByUserId = actorUserId;
            entity.EndedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return MapToDto(entity);
        }

        public AdDTO Delete(Guid id, Guid? actorUserId)
        {
            // Soft-delete + TotalAds decrement are two saves — commit atomically.
            using var tx = _context.Database.BeginTransaction();

            // Record who performed the delete before the base soft-delete saves.
            var entity = _context.Ads.Find(id);
            if (entity != null)
                entity.DeletedByUserId = actorUserId;

            var result = Delete(id);
            tx.Commit();
            return result;
        }

        private AdDTO MapToDto(Ad entity)
        {
            var dto = entity.Adapt<AdDTO>();
            dto.Type = entity.AdType.ToString().ToUpper();
            dto.Status = entity.Status?.ToString() ?? "Active";

            if (entity.User != null)
            {
                dto.OwnerUsername = entity.User.Email;
                dto.OwnerFullName = $"{entity.User.FirstName} {entity.User.LastName}".Trim();
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
