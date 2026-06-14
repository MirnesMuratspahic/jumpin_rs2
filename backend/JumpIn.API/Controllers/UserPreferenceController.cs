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
    public class UserPreferenceController : BaseCRUDController<UserPreferenceDTO, UserPreferenceSearchObject, UserPreferenceInsertRequest, UserPreferenceUpdateRequest>
    {
        public UserPreferenceController(IUserPreferenceService service) : base(service) { }

        public override UserPreferenceDTO Insert([FromBody] UserPreferenceInsertRequest request)
        {
            if (CurrentUserId != null) request.UserId = CurrentUserId.Value;
            return _service.Insert(request);
        }

        public override UserPreferenceDTO Update(Guid id, [FromBody] UserPreferenceUpdateRequest request)
        {
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.UserId);
            return _service.Update(id, request);
        }

        public override UserPreferenceDTO Delete(Guid id)
        {
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.UserId);
            return _service.Delete(id);
        }
    }
}
