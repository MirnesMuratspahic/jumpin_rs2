using JumpIn.Models.DTOs;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class ActivityLogController : ControllerBase
    {
        private readonly IActivityLogService _activityLogService;

        public ActivityLogController(IActivityLogService activityLogService)
        {
            _activityLogService = activityLogService;
        }

        [HttpGet]
        public async Task<IActionResult> GetList([FromQuery] ActivityLogSearchObject search)
        {
            return Ok(await _activityLogService.GetPagedAsync(search));
        }

        [HttpGet("{id}")]
        public IActionResult GetById(int id)
        {
            return Ok(_activityLogService.GetById(id));
        }

        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetByUser(int userId, [FromQuery] int count = 20)
        {
            return Ok(await _activityLogService.GetByUserAsync(userId, count));
        }
    }
}
