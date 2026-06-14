using JumpIn.API.Controllers.BaseControllers;
using JumpIn.Models.DTOs;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdImageController : BaseCRUDController<AdImageDTO, AdImageSearchObject, AdImageInsertRequest, AdImageUpdateRequest>
    {
        private readonly IAdService _adService;

        public AdImageController(IAdImageService service, IAdService adService) : base(service)
        {
            _adService = adService;
        }

        // An image may only be managed by the owner of its ad (or an admin).
        private void EnsureOwnsAd(Guid adId)
        {
            var ad = _adService.GetById(adId);
            EnsureOwnerOrAdmin(ad.UserId);
        }

        public override AdImageDTO Insert([FromBody] AdImageInsertRequest request)
        {
            EnsureOwnsAd(request.AdId);
            return _service.Insert(request);
        }

        public override AdImageDTO Update(Guid id, [FromBody] AdImageUpdateRequest request)
        {
            var existing = _service.GetById(id);
            EnsureOwnsAd(existing.AdId);
            return _service.Update(id, request);
        }

        public override AdImageDTO Delete(Guid id)
        {
            var existing = _service.GetById(id);
            EnsureOwnsAd(existing.AdId);
            return _service.Delete(id);
        }
    }
}
