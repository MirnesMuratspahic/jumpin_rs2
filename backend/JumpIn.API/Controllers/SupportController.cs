using JumpIn.API.Controllers.BaseControllers;
using JumpIn.Models.Constants;
using JumpIn.Models.DTOs;
using JumpIn.Models.HelperClasses;
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

        public override async Task<PagedResult<SupportMessageDTO>> GetList([FromQuery] SupportSearchObject search)
        {
            // A user may only list their own tickets; admins see everything.
            if (!IsAdmin && CurrentUserId != null) search.UserId = CurrentUserId.Value;
            return await _service.GetPagedAsync(search);
        }

        public override SupportMessageDTO GetById(Guid id)
        {
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.UserId);
            return existing;
        }

        public override SupportMessageDTO Insert([FromBody] SupportInsertRequest request)
        {
            if (CurrentUserId != null) request.UserId = CurrentUserId.Value;
            return _service.Insert(request);
        }

        [Authorize(Roles = RoleNames.Admin)]
        public override SupportMessageDTO Update(Guid id, [FromBody] SupportUpdateRequest request)
        {
            return _service.Update(id, request);
        }

        [Authorize(Roles = RoleNames.Admin)]
        [HttpPost("{id}/respond")]
        public SupportMessageDTO RespondToMessage(Guid id, [FromBody] SupportRespondRequest request)
        {
            return _supportService.RespondToMessage(id, request.AdminResponse);
        }
    }
}
