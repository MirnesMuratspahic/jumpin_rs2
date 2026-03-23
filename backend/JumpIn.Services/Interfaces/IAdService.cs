using JumpIn.Models.DTOs;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseInterfaces;

namespace JumpIn.Services.Interfaces
{
    public interface IAdService : ICRUDService<AdDTO, AdSearchObject, AdInsertRequest, AdUpdateRequest>
    {
    }
}
