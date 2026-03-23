using JumpIn.Models.HelperClasses;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseInterfaces;
using JumpIn.Services.Database;
using Mapster;

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

            var totalCount = query.Count();

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value)
                             .Take(search.PageSize.Value);
            }

            var list = query.ToList();
            var result = list.Adapt<List<TModel>>();

            return new PagedResult<TModel>
            {
                ResultList = result,
                Count = totalCount
            };
        }

        public virtual TModel GetById(int id)
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
