using JumpIn.Models.DTOs;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseInterfaces;

namespace JumpIn.Services.Interfaces
{
    public interface IAdService : ICRUDService<AdDTO, AdSearchObject, AdInsertRequest, AdUpdateRequest>
    {
        // ownerCheckUserId: when set, the ad must belong to this user (null = admin, no check).
        // actorUserId: the user actually performing the action, recorded for the audit trail.
        Task<AdDTO> EndAdAsync(Guid id, Guid? ownerCheckUserId = null, Guid? actorUserId = null);

        // Deletes an ad and records which user performed it.
        AdDTO Delete(Guid id, Guid? actorUserId);
    }
}
