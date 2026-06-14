using JumpIn.Models.DTOs;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseInterfaces;

namespace JumpIn.Services.Interfaces
{
    public interface IUserService : ICRUDService<UserModel, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        Task<UserModel> LoginAsync(LoginRequest request);
        Task<UserModel> BlockUserAsync(Guid id, BlockUserRequest request);
        Task<UserModel> UnblockUserAsync(Guid id);
        Task<UserModel> ActivateVipAsync(Guid id);
        Task<UserStatistics> GetUserStatisticsAsync(Guid id);
        Task LogoutAsync(Guid id);
        Task ChangePasswordAsync(Guid id, ChangePasswordRequest request, bool requireCurrentPassword);
        Task RequestPasswordResetAsync(string email);
        Task ResetPasswordAsync(ResetPasswordRequest request);
    }
}
