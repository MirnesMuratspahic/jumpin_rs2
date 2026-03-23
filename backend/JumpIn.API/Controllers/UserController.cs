using JumpIn.API.Auth;
using JumpIn.API.Controllers.BaseControllers;
using JumpIn.Models.DTOs;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
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

        [Authorize(Roles = "Admin")]
        [HttpPost("{id}/block")]
        public async Task<UserModel> BlockUser(int id, [FromBody] BlockUserRequest request)
        {
            return await _userService.BlockUserAsync(id, request);
        }

        [Authorize(Roles = "Admin")]
        [HttpPost("{id}/unblock")]
        public async Task<UserModel> UnblockUser(int id)
        {
            return await _userService.UnblockUserAsync(id);
        }

        [HttpPost("{id}/activate-vip")]
        public async Task<UserModel> ActivateVip(int id)
        {
            return await _userService.ActivateVipAsync(id);
        }

        [HttpGet("{id}/statistics")]
        public async Task<UserStatistics> GetStatistics(int id)
        {
            return await _userService.GetUserStatisticsAsync(id);
        }
    }
}
