using JumpIn.Models.DTOs;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseInterfaces;

namespace JumpIn.Services.Interfaces
{
    public interface IReviewService : ICRUDService<ReviewDTO, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
        List<ReviewDTO> GetReviewsByUser(Guid userId);
        ReviewDTO CreateReviewForUser(Guid reviewedUserId, ReviewInsertRequest request);
    }
}
