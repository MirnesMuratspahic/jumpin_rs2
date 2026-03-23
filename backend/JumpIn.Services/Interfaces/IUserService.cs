using JumpIn.Models.DTOs;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseInterfaces;

namespace JumpIn.Services.Interfaces
{
    public interface IUserService : ICRUDService<UserModel, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        Task<UserModel> LoginAsync(LoginRequest request);
        Task<UserModel> BlockUserAsync(int id, BlockUserRequest request);
        Task<UserModel> UnblockUserAsync(int id);
        Task<UserModel> ActivateVipAsync(int id);
        Task<UserStatistics> GetUserStatisticsAsync(int id);
    }
}
