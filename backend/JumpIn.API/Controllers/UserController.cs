using JumpIn.API.Auth;
using JumpIn.API.Controllers.BaseControllers;
using JumpIn.API.Helpers;
using JumpIn.Models.Constants;
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

        [AllowAnonymous]
        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            await _userService.RequestPasswordResetAsync(request.Email);
            // Always 200 — never reveal whether an account with that email exists.
            return Ok(new { message = "If an account with that email exists, a reset code has been sent." });
        }

        [AllowAnonymous]
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            await _userService.ResetPasswordAsync(request);
            return Ok(new { message = "Your password has been reset. You can now log in." });
        }

        [HttpPost("logout")]
        public async Task<IActionResult> Logout()
        {
            if (CurrentUserId == null) return Unauthorized();
            // Invalidates all previously-issued tokens for this user server-side.
            await _userService.LogoutAsync(CurrentUserId.Value);
            return Ok(new { message = "Logged out." });
        }

        [HttpPost("{id}/change-password")]
        public async Task<IActionResult> ChangePassword(Guid id, [FromBody] ChangePasswordRequest request)
        {
            EnsureOwnerOrAdmin(id);
            // Changing your OWN password requires the current password; an admin
            // changing another user's does not.
            var requireCurrent = CurrentUserId == id;
            await _userService.ChangePasswordAsync(id, request, requireCurrent);
            return Ok(new { message = "Password changed successfully." });
        }

        // The full user list (with email/phone/role/status) is admin-only.
        [Authorize(Roles = RoleNames.Admin)]
        public override async Task<PagedResult<UserModel>> GetList([FromQuery] UserSearchObject search)
        {
            return await base.GetList(search);
        }

        // The full user record (email, phone, role, status…) is only for the owner
        // or an admin. Other users must use the public profile endpoints below.
        public override UserModel GetById(Guid id)
        {
            EnsureOwnerOrAdmin(id);
            return _service.GetById(id);
        }

        [Authorize(Roles = RoleNames.Admin)]
        public override UserModel Insert([FromBody] UserInsertRequest request)
        {
            return _service.Insert(request);
        }

        public override UserModel Update(Guid id, [FromBody] UserUpdateRequest request)
        {
            // A user may edit only their own profile; admins may edit anyone.
            EnsureOwnerOrAdmin(id);
            return _service.Update(id, request);
        }

        [Authorize(Roles = RoleNames.Admin)]
        public override UserModel Delete(Guid id)
        {
            return _service.Delete(id);
        }

        [Authorize(Roles = RoleNames.Admin)]
        [HttpPost("{id}/block")]
        public async Task<UserModel> BlockUser(Guid id, [FromBody] BlockUserRequest request)
        {
            return await _userService.BlockUserAsync(id, request);
        }

        [Authorize(Roles = RoleNames.Admin)]
        [HttpPost("{id}/unblock")]
        public async Task<UserModel> UnblockUser(Guid id)
        {
            return await _userService.UnblockUserAsync(id);
        }

        [HttpGet("{id}/statistics")]
        public async Task<UserStatistics> GetStatistics(Guid id)
        {
            return await _userService.GetUserStatisticsAsync(id);
        }

        // SMS phone verification — sends a code to the user's phone (sandbox delivery).
        [HttpPost("{id}/send-phone-code")]
        public async Task<IActionResult> SendPhoneCode(Guid id)
        {
            EnsureOwnerOrAdmin(id);
            await _userService.SendPhoneVerificationCodeAsync(id);
            return Ok(new { message = "A verification code has been sent." });
        }

        // Confirms the code and marks the phone number as verified.
        [HttpPost("{id}/verify-phone")]
        public async Task<UserModel> VerifyPhone(Guid id, [FromBody] VerifyPhoneRequest request)
        {
            EnsureOwnerOrAdmin(id);
            return await _userService.VerifyPhoneAsync(id, request?.Code);
        }

        // Public profile (any authenticated user). Returns ONLY public-safe fields —
        // no email/phone/role/status — plus public statistics.
        [HttpGet("{id}/profile")]
        public async Task<IActionResult> GetUserProfile(Guid id)
        {
            var user = _service.GetById(id);
            if (user == null)
                return NotFound("User not found");

            var statistics = await _userService.GetUserStatisticsAsync(id);

            return Ok(new
            {
                user = ToPublicProfile(user),
                statistics
            });
        }

        // Public profile object on its own (used by the mobile "view user" screen).
        [HttpGet("{id}/public")]
        public IActionResult GetPublicProfile(Guid id)
        {
            var user = _service.GetById(id);
            if (user == null)
                return NotFound("User not found");

            return Ok(ToPublicProfile(user));
        }

        private static PublicUserProfileDTO ToPublicProfile(UserModel user) => new()
        {
            Id = user.Id,
            FirstName = user.FirstName,
            LastName = user.LastName,
            ProfileImageUrl = user.ProfileImageUrl,
            RegistrationDate = user.RegistrationDate,
            IsVip = user.IsVip,
            AverageRating = user.AverageRating,
            TotalReviews = user.TotalReviews,
            TotalAds = user.TotalAds
        };

        [HttpPost("upload-image")]
        public async Task<IActionResult> UploadProfileImage(IFormFile file, [FromServices] IWebHostEnvironment environment)
        {
            var (ok, error) = ImageFileValidator.Validate(file);
            if (!ok)
                return BadRequest(new { message = error });

            try
            {
                var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
                var uploadDir = Path.Combine(environment.WebRootPath, "uploads", "profile-images");

                if (!Directory.Exists(uploadDir))
                    Directory.CreateDirectory(uploadDir);

                var uniqueFileName = $"{Guid.NewGuid()}{extension}";
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
            EnsureOwnerOrAdmin(id);

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
