using JumpIn.API.Controllers.BaseControllers;
using JumpIn.Models.DTOs;
using JumpIn.Models.HelperClasses;
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

        // A regular user sees only their own preferences (owner from the JWT). Admins see all.
        public override async Task<PagedResult<UserPreferenceDTO>> GetList([FromQuery] UserPreferenceSearchObject search)
        {
            if (!IsAdmin) search.UserId = CurrentUserId;
            return await base.GetList(search);
        }

        public override UserPreferenceDTO GetById(Guid id)
        {
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.UserId);
            return existing;
        }

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
