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
    public class FavoriteController : BaseCRUDController<FavoriteDTO, FavoriteSearchObject, FavoriteInsertRequest, FavoriteUpdateRequest>
    {
        public FavoriteController(IFavoriteService service) : base(service) { }
    }
}
