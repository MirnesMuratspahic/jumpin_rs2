using JumpIn.API.Controllers.BaseControllers;
using JumpIn.Models.DTOs;
using JumpIn.Models.Exceptions;
using JumpIn.Models.HelperClasses;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RequestController : BaseCRUDController<RequestDTO, RequestSearchObject, RequestInsertRequest, RequestUpdateRequest>
    {
        private readonly IRequestService _requestService;

        public RequestController(IRequestService service) : base(service)
        {
            _requestService = service;
        }

        // A regular user sees only requests they are involved in (sender or receiver),
        // scoped from the JWT. Admins see all.
        public override async Task<PagedResult<RequestDTO>> GetList([FromQuery] RequestSearchObject search)
        {
            if (!IsAdmin) search.InvolvedUserId = CurrentUserId;
            return await base.GetList(search);
        }

        public override RequestDTO Insert([FromBody] RequestInsertRequest request)
        {
            // Sender always comes from the authenticated user, never the request body.
            if (CurrentUserId != null) request.SenderId = CurrentUserId.Value;
            return _service.Insert(request);
        }

        public override RequestDTO GetById(Guid id)
        {
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.SenderId, existing.ReceiverId);
            return existing;
        }

        // Generic status update is intentionally disabled — status changes only via
        // the accept/decline actions, which enforce the allowed transitions, record
        // who responded and notify the sender.
        public override RequestDTO Update(Guid id, [FromBody] RequestUpdateRequest request)
        {
            throw new UserException("Request status can only be changed through the accept or decline actions.");
        }

        public override RequestDTO Delete(Guid id)
        {
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.SenderId, existing.ReceiverId);
            return _service.Delete(id);
        }

        [HttpPost("{id}/accept")]
        public async Task<RequestDTO> AcceptRequest(Guid id)
        {
            // Only the receiver of the request (or an admin) may accept it.
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.ReceiverId);
            return await _requestService.AcceptRequestAsync(id, CurrentUserId!.Value);
        }

        [HttpPost("{id}/decline")]
        public async Task<RequestDTO> DeclineRequest(Guid id, [FromBody] DeclineRequestRequest? request = null)
        {
            // Only the receiver of the request (or an admin) may decline it.
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.ReceiverId);
            return await _requestService.DeclineRequestAsync(id, CurrentUserId!.Value, request?.Reason);
        }
    }
}
