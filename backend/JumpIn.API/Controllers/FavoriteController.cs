using JumpIn.API.Controllers.BaseControllers;
using JumpIn.Models.DTOs;
using JumpIn.Models.HelperClasses;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FavoriteController : BaseCRUDController<FavoriteDTO, FavoriteSearchObject, FavoriteInsertRequest, FavoriteUpdateRequest>
    {
        public FavoriteController(IFavoriteService service) : base(service) { }

        // A regular user sees only their own favorites; the owner filter comes from
        // the JWT, never from a client-supplied query parameter. Admins see all.
        public override async Task<PagedResult<FavoriteDTO>> GetList([FromQuery] FavoriteSearchObject search)
        {
            if (!IsAdmin) search.UserId = CurrentUserId;
            return await base.GetList(search);
        }

        public override FavoriteDTO GetById(Guid id)
        {
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.UserId);
            return existing;
        }

        public override FavoriteDTO Insert([FromBody] FavoriteInsertRequest request)
        {
            if (CurrentUserId != null) request.UserId = CurrentUserId.Value;
            return _service.Insert(request);
        }

        public override FavoriteDTO Delete(Guid id)
        {
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.UserId);
            return _service.Delete(id);
        }
    }
}
