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
    public class FavoriteService : BaseCRUDService<FavoriteDTO, FavoriteSearchObject, Favorite, FavoriteInsertRequest, FavoriteUpdateRequest>, IFavoriteService
    {
        public FavoriteService(JumpInDbContext context) : base(context) { }

        public override async Task<PagedResult<FavoriteDTO>> GetPagedAsync(FavoriteSearchObject search)
        {
            var query = _context.Favorites
                .Include(f => f.User)
                .Include(f => f.Ad)
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

            return new PagedResult<FavoriteDTO>
            {
                ResultList = result,
                Count = totalCount
            };
        }

        protected override IQueryable<Favorite> AddFilter(IQueryable<Favorite> query, FavoriteSearchObject search)
        {
            if (search.UserId.HasValue)
                query = query.Where(f => f.UserId == search.UserId.Value);

            if (search.AdId.HasValue)
                query = query.Where(f => f.AdId == search.AdId.Value);

            return query;
        }

        protected override void BeforeInsert(FavoriteInsertRequest request, Favorite entity)
        {
            var user = _context.Users.Find(request.UserId);
            if (user == null || user.IsDeleted)
                throw new UserException("User not found.");

            var ad = _context.Ads.Find(request.AdId);
            if (ad == null || ad.IsDeleted)
                throw new UserException("Ad not found.");

            var existing = _context.Favorites.FirstOrDefault(f => f.UserId == request.UserId && f.AdId == request.AdId);
            if (existing != null)
                throw new UserException("Ad is already in favorites.");

            entity.CreatedAt = DateTime.UtcNow;
        }

        private FavoriteDTO MapToDto(Favorite entity)
        {
            var dto = entity.Adapt<FavoriteDTO>();

            if (entity.User != null)
                dto.UserName = $"{entity.User.FirstName} {entity.User.LastName}";

            if (entity.Ad != null)
            {
                dto.AdTitle = entity.Ad.Title;
                dto.AdType = entity.Ad.AdType.ToString().ToUpper();
                dto.AdImageUrl = entity.Ad.ImageUrl;
            }

            return dto;
        }
    }
}
