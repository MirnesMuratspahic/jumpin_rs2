using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseInterfaces;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers.BaseControllers
{
    public class BaseCRUDController<TModel, TSearch, TInsert, TUpdate> : BaseController<TModel, TSearch>
        where TSearch : BaseSearchObject
    {
        protected new readonly ICRUDService<TModel, TSearch, TInsert, TUpdate> _service;

        public BaseCRUDController(ICRUDService<TModel, TSearch, TInsert, TUpdate> service) : base(service)
        {
            _service = service;
        }

        [HttpPost]
        public virtual TModel Insert([FromBody] TInsert request)
        {
            return _service.Insert(request);
        }

        [HttpPut("{id}")]
        public virtual TModel Update(Guid id, [FromBody] TUpdate request)
        {
            return _service.Update(id, request);
        }

        [HttpDelete("{id}")]
        public virtual TModel Delete(Guid id)
        {
            return _service.Delete(id);
        }
    }
}
