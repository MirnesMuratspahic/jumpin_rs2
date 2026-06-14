using JumpIn.Models.HelperClasses;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseInterfaces;
using JumpIn.Services.Database;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace JumpIn.Services.BaseServices
{
    public class BaseService<TModel, TSearch, TDbEntity> : IService<TModel, TSearch>
        where TSearch : BaseSearchObject
        where TDbEntity : class
    {
        protected JumpInDbContext _context;

        public BaseService(JumpInDbContext context)
        {
            _context = context;
        }

        public virtual async Task<PagedResult<TModel>> GetPagedAsync(TSearch search)
        {
            var query = _context.Set<TDbEntity>().AsQueryable();

            query = AddFilter(query, search);
            query = ApplySorting(query, search);

            var totalCount = await query.CountAsync();

            query = query.ApplyPaging(search);

            var list = await query.ToListAsync();
            var result = list.Adapt<List<TModel>>();

            return new PagedResult<TModel>
            {
                ResultList = result,
                Count = totalCount
            };
        }

        public virtual TModel GetById(Guid id)
        {
            var entity = _context.Set<TDbEntity>().Find(id);

            if (entity == null)
                throw new Exception("Entity not found");

            if (entity is ISoftDeletable softDeletable && softDeletable.IsDeleted)
                throw new Exception("Entity not found");

            return entity.Adapt<TModel>();
        }

        protected virtual IQueryable<TDbEntity> AddFilter(IQueryable<TDbEntity> query, TSearch search)
        {
            return query;
        }

        protected virtual IQueryable<TDbEntity> ApplySorting(IQueryable<TDbEntity> query, TSearch search)
        {
            if (!string.IsNullOrEmpty(search?.OrderBy))
            {
                var direction = search.SortDirection?.ToLower() == "desc" ? "descending" : "ascending";
                try
                {
                    query = System.Linq.Dynamic.Core.DynamicQueryableExtensions.OrderBy(query, $"{search.OrderBy} {direction}");
                }
                catch
                {
                    // Invalid property name, ignore sorting
                }
            }

            return query;
        }
    }
}
