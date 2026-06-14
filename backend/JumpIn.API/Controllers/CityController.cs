using JumpIn.API.Controllers.BaseControllers;
using JumpIn.Models.Constants;
using JumpIn.Models.DTOs;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CityController : BaseCRUDController<CityDTO, CitySearchObject, CityInsertRequest, CityUpdateRequest>
    {
        public CityController(ICityService service) : base(service)
        {
        }

        // Cities are reference data: anyone authenticated may read, only admins may modify.
        [Authorize(Roles = RoleNames.Admin)]
        public override CityDTO Insert([FromBody] CityInsertRequest request) => _service.Insert(request);

        [Authorize(Roles = RoleNames.Admin)]
        public override CityDTO Update(Guid id, [FromBody] CityUpdateRequest request) => _service.Update(id, request);

        [Authorize(Roles = RoleNames.Admin)]
        public override CityDTO Delete(Guid id) => _service.Delete(id);
    }
}
