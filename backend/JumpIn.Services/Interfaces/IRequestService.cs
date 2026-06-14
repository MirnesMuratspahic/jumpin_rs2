using JumpIn.Models.DTOs;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseInterfaces;

namespace JumpIn.Services.Interfaces
{
    public interface IRequestService : ICRUDService<RequestDTO, RequestSearchObject, RequestInsertRequest, RequestUpdateRequest>
    {
        Task<RequestDTO> AcceptRequestAsync(Guid id);
        Task<RequestDTO> DeclineRequestAsync(Guid id);
    }
}
