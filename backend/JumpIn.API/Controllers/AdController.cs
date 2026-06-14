using JumpIn.API.Controllers.BaseControllers;
using JumpIn.API.Helpers;
using JumpIn.Models.DTOs;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdController : BaseCRUDController<AdDTO, AdSearchObject, AdInsertRequest, AdUpdateRequest>
    {
        private readonly IWebHostEnvironment _env;
        private readonly IAdService _adService;

        public AdController(IAdService service, IWebHostEnvironment env) : base(service)
        {
            _env = env;
            _adService = service;
        }

        public override AdDTO Insert([FromBody] AdInsertRequest request)
        {
            // Owner always comes from the authenticated user, never the request body.
            if (CurrentUserId != null) request.UserId = CurrentUserId.Value;
            return _service.Insert(request);
        }

        public override AdDTO Update(Guid id, [FromBody] AdUpdateRequest request)
        {
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.UserId);
            return _service.Update(id, request);
        }

        public override AdDTO Delete(Guid id)
        {
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.UserId);
            // Record the acting user (owner or admin) for the audit trail.
            return _adService.Delete(id, CurrentUserId);
        }

        [HttpPost("{id}/end")]
        public async Task<AdDTO> EndAd(Guid id)
        {
            // Admins may end any ad; a user may only end their own. Either way we
            // record who actually performed the action.
            var ownerCheck = IsAdmin ? (Guid?)null : CurrentUserId;
            return await _adService.EndAdAsync(id, ownerCheck, CurrentUserId);
        }

        [HttpPost("upload-image")]
        public async Task<IActionResult> UploadImage(IFormFile file)
        {
            var (ok, error) = ImageFileValidator.Validate(file);
            if (!ok)
                return BadRequest(new { message = error });

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            var uploadsDir = Path.Combine(_env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot"), "uploads");
            Directory.CreateDirectory(uploadsDir);

            var fileName = $"{Guid.NewGuid()}{extension}";
            var filePath = Path.Combine(uploadsDir, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var imageUrl = $"{Request.Scheme}://{Request.Host}/uploads/{fileName}";
            return Ok(new { imageUrl });
        }
    }
}
