using JumpIn.API.Auth;
using JumpIn.API.Controllers.BaseControllers;
using JumpIn.Models.DTOs;
using JumpIn.Models.HelperClasses;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UserController : BaseCRUDController<UserModel, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        private readonly IUserService _userService;
        private readonly ITokenService _tokenService;

        public UserController(IUserService service, ITokenService tokenService) : base(service)
        {
            _userService = service;
            _tokenService = tokenService;
        }

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<LoginResponse> Login([FromBody] LoginRequest request)
        {
            var user = await _userService.LoginAsync(request);
            var token = _tokenService.GenerateToken(user);
            return new LoginResponse { User = user, Token = token };
        }

        [AllowAnonymous]
        [HttpPost("register")]
        public UserModel Register([FromBody] UserInsertRequest request)
        {
            return _service.Insert(request);
        }

        [Authorize(Roles = "ADMIN")]
        [HttpPost("{id}/block")]
        public async Task<UserModel> BlockUser(Guid id, [FromBody] BlockUserRequest request)
        {
            return await _userService.BlockUserAsync(id, request);
        }

        [Authorize(Roles = "ADMIN")]
        [HttpPost("{id}/unblock")]
        public async Task<UserModel> UnblockUser(Guid id)
        {
            return await _userService.UnblockUserAsync(id);
        }

        [HttpPost("{id}/activate-vip")]
        public async Task<UserModel> ActivateVip(Guid id)
        {
            return await _userService.ActivateVipAsync(id);
        }

        [HttpGet("{id}/statistics")]
        public async Task<UserStatistics> GetStatistics(Guid id)
        {
            return await _userService.GetUserStatisticsAsync(id);
        }

        [HttpGet("{id}/profile")]
        public async Task<IActionResult> GetUserProfile(Guid id)
        {
            var user = _service.GetById(id);
            if (user == null)
                return NotFound("User not found");

            var statistics = await _userService.GetUserStatisticsAsync(id);

            return Ok(new
            {
                user,
                statistics
            });
        }

        [HttpPost("upload-image")]
        public async Task<IActionResult> UploadProfileImage(IFormFile file, [FromServices] IWebHostEnvironment environment)
        {
            if (file == null || file.Length == 0)
                return BadRequest("No file provided");

            try
            {
                var fileName = Path.GetFileName(file.FileName);
                var uploadDir = Path.Combine(environment.WebRootPath, "uploads", "profile-images");

                if (!Directory.Exists(uploadDir))
                    Directory.CreateDirectory(uploadDir);

                var uniqueFileName = $"{Guid.NewGuid()}_{fileName}";
                var filePath = Path.Combine(uploadDir, uniqueFileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                var imageUrl = $"{Request.Scheme}://{Request.Host}/uploads/profile-images/{uniqueFileName}";
                return Ok(new { imageUrl });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error uploading file", error = ex.Message });
            }
        }

        [HttpPut("{id}/profile-image")]
        public IActionResult UpdateProfileImage(Guid id, [FromBody] ProfileImageUpdateRequest request)
        {
            var user = _service.GetById(id);
            if (user == null)
                return NotFound("User not found");

            if (string.IsNullOrEmpty(request?.ProfileImageUrl))
                return BadRequest("Profile image URL is required");

            var updateRequest = new UserUpdateRequest { ProfileImageUrl = request.ProfileImageUrl };
            var updated = _service.Update(id, updateRequest);

            return Ok(updated);
        }
    }
}
