using System.Security.Claims;
using JumpIn.Models.DTOs;
using JumpIn.Models.HelperClasses;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class NotificationController : ControllerBase
    {
        private readonly INotificationService _service;

        public NotificationController(INotificationService service)
        {
            _service = service;
        }

        private Guid? CurrentUserId =>
            Guid.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : null;

        // A user only ever sees their own notifications.
        [HttpGet]
        public async Task<PagedResult<NotificationDTO>> GetList([FromQuery] NotificationSearchObject search)
        {
            search.UserId = CurrentUserId;
            return await _service.GetPagedAsync(search);
        }

        [HttpGet("unread-count")]
        public async Task<IActionResult> GetUnreadCount()
        {
            if (CurrentUserId == null) return Ok(new { count = 0 });
            var count = await _service.GetUnreadCountAsync(CurrentUserId.Value);
            return Ok(new { count });
        }

        [HttpPut("{id}/read")]
        public async Task<NotificationDTO> MarkRead(Guid id)
        {
            return await _service.MarkReadAsync(id, CurrentUserId ?? Guid.Empty);
        }

        [HttpPut("read-all")]
        public async Task<IActionResult> MarkAllRead()
        {
            if (CurrentUserId != null)
                await _service.MarkAllReadAsync(CurrentUserId.Value);
            return Ok();
        }
    }
}
