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
    }
}
