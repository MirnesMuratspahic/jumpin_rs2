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
    public class AdImageService : BaseCRUDService<AdImageDTO, AdImageSearchObject, AdImage, AdImageInsertRequest, AdImageUpdateRequest>, IAdImageService
    {
        public AdImageService(JumpInDbContext context) : base(context) { }

        public override async Task<PagedResult<AdImageDTO>> GetPagedAsync(AdImageSearchObject search)
        {
            var query = _context.AdImages.AsQueryable();

            query = AddFilter(query, search);
            query = ApplySorting(query, search);

            var totalCount = await query.CountAsync();

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value)
                             .Take(search.PageSize.Value);
            }

            var list = await query.ToListAsync();
            var result = list.Select(a => a.Adapt<AdImageDTO>()).ToList();

            return new PagedResult<AdImageDTO>
            {
                ResultList = result,
                Count = totalCount
            };
        }

        protected override IQueryable<AdImage> AddFilter(IQueryable<AdImage> query, AdImageSearchObject search)
        {
            if (search.AdId.HasValue)
                query = query.Where(ai => ai.AdId == search.AdId.Value);

            if (search.IsMainImage.HasValue)
                query = query.Where(ai => ai.IsMainImage == search.IsMainImage.Value);

            return query;
        }

        protected override void BeforeInsert(AdImageInsertRequest request, AdImage entity)
        {
            var ad = _context.Ads.Find(request.AdId);
            if (ad == null || ad.IsDeleted)
                throw new UserException("Ad not found.");

            entity.CreatedAt = DateTime.UtcNow;
        }
    }
}
