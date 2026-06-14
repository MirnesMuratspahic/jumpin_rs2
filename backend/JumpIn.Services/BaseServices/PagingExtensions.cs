using JumpIn.Models.SearchObjects;

namespace JumpIn.Services.BaseServices
{
    /// Centralized, mandatory paging with a hard maximum page size so no list
    /// endpoint can return an unbounded result set.
    public static class PagingExtensions
    {
        public const int MaxPageSize = 100;
        public const int DefaultPageSize = 100;

        public static IQueryable<T> ApplyPaging<T>(this IQueryable<T> query, BaseSearchObject? search)
        {
            var page = (search?.Page is int p && p > 0) ? p : 1;
            var requested = search?.PageSize ?? DefaultPageSize;
            var pageSize = Math.Clamp(requested, 1, MaxPageSize);
            return query.Skip((page - 1) * pageSize).Take(pageSize);
        }
    }
}
