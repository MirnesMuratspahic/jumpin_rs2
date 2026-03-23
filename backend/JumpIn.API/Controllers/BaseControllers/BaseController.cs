using JumpIn.Models.HelperClasses;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseInterfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers.BaseControllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class BaseController<TModel, TSearch> : ControllerBase
        where TSearch : BaseSearchObject
    {
        protected readonly IService<TModel, TSearch> _service;

        public BaseController(IService<TModel, TSearch> service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<PagedResult<TModel>> GetList([FromQuery] TSearch search)
        {
            return await _service.GetPagedAsync(search);
        }

        [HttpGet("{id}")]
        public TModel GetById(int id)
        {
            return _service.GetById(id);
        }
    }
}
