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
        private readonly ISupportService _supportService;

        public SupportController(ISupportService service) : base(service)
        {
            _supportService = service;
        }

        [Authorize(Roles = "ADMIN")]
        [HttpPut("{id}")]
        public new SupportMessageDTO Update(Guid id, [FromBody] SupportUpdateRequest request)
        {
            return _service.Update(id, request);
        }

        [Authorize(Roles = "ADMIN")]
        [HttpPost("{id}/respond")]
        public SupportMessageDTO RespondToMessage(Guid id, [FromBody] SupportRespondRequest request)
        {
            return _supportService.RespondToMessage(id, request.AdminResponse);
        }
    }
}
