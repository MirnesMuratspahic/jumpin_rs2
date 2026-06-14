using JumpIn.API.Controllers.BaseControllers;
using JumpIn.Models.DTOs;
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

        public override RequestDTO Update(Guid id, [FromBody] RequestUpdateRequest request)
        {
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.SenderId, existing.ReceiverId);
            return _service.Update(id, request);
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
            return await _requestService.AcceptRequestAsync(id);
        }

        [HttpPost("{id}/decline")]
        public async Task<RequestDTO> DeclineRequest(Guid id)
        {
            // Only the receiver of the request (or an admin) may decline it.
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.ReceiverId);
            return await _requestService.DeclineRequestAsync(id);
        }
    }
}
