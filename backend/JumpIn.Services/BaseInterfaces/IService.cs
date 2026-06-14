using JumpIn.Models.HelperClasses;

namespace JumpIn.Services.BaseInterfaces
{
    public interface IService<TModel, TSearch>
    {
        Task<PagedResult<TModel>> GetPagedAsync(TSearch search);
        TModel GetById(Guid id);
    }
}
