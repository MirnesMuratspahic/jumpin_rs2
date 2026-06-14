using JumpIn.Models.DTOs;
using JumpIn.Models.HelperClasses;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseServices;
using JumpIn.Services.Database;
using JumpIn.Services.Interfaces;
using Mapster;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace JumpIn.Services.Services
{
    public class CityService : BaseCRUDService<CityDTO, CitySearchObject, City, CityInsertRequest, CityUpdateRequest>, ICityService
    {
        private readonly IMemoryCache _cache;
        private const string CacheKey = "cities_all";

        public CityService(JumpInDbContext context, IMemoryCache cache) : base(context)
        {
            _cache = cache;
        }

        // Cities are reference data read very frequently and changed rarely —
        // serve the full list from IMemoryCache and filter/page in memory.
        public override async Task<PagedResult<CityDTO>> GetPagedAsync(CitySearchObject search)
        {
            var all = await _cache.GetOrCreateAsync(CacheKey, async entry =>
            {
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10);
                var cities = await _context.Cities.OrderBy(c => c.Name).ToListAsync();
                return cities.Select(c => c.Adapt<CityDTO>()).ToList();
            }) ?? new List<CityDTO>();

            IEnumerable<CityDTO> query = all;
            if (!string.IsNullOrEmpty(search.Name))
            {
                var name = search.Name.ToLower();
                query = query.Where(c => (c.Name ?? string.Empty).ToLower().Contains(name));
            }

            var totalCount = query.Count();
            var page = (search.Page is int p && p > 0) ? p : 1;
            var pageSize = Math.Clamp(search.PageSize ?? PagingExtensions.DefaultPageSize, 1, PagingExtensions.MaxPageSize);
            var items = query.Skip((page - 1) * pageSize).Take(pageSize).ToList();

            return new PagedResult<CityDTO> { ResultList = items, Count = totalCount };
        }

        public override CityDTO Insert(CityInsertRequest request)
        {
            var result = base.Insert(request);
            _cache.Remove(CacheKey);
            return result;
        }

        public override CityDTO Update(Guid id, CityUpdateRequest request)
        {
            var result = base.Update(id, request);
            _cache.Remove(CacheKey);
            return result;
        }

        public override CityDTO Delete(Guid id)
        {
            var result = base.Delete(id);
            _cache.Remove(CacheKey);
            return result;
        }

        protected override IQueryable<City> AddFilter(IQueryable<City> query, CitySearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
            {
                var name = search.Name.ToLower();
                query = query.Where(c => c.Name.ToLower().Contains(name));
            }

            return query;
        }
    }
}
