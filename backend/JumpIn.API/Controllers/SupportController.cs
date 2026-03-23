using JumpIn.API.Controllers.BaseControllers;
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
    public class SupportController : BaseCRUDController<SupportMessageDTO, SupportSearchObject, SupportInsertRequest, SupportUpdateRequest>
    {
        public SupportController(ISupportService service) : base(service) { }

        [Authorize(Roles = "Admin")]
        [HttpPut("{id}")]
        public new SupportMessageDTO Update(int id, [FromBody] SupportUpdateRequest request)
        {
            return _service.Update(id, request);
        }
    }
}
