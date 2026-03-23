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

        [HttpPost("{id}/accept")]
        public async Task<RequestDTO> AcceptRequest(int id)
        {
            return await _requestService.AcceptRequestAsync(id);
        }

        [HttpPost("{id}/decline")]
        public async Task<RequestDTO> DeclineRequest(int id)
        {
            return await _requestService.DeclineRequestAsync(id);
        }
    }
}
