using System.Linq;
using System.Security.Claims;
using JumpIn.Models.Constants;
using JumpIn.Models.Exceptions;
using JumpIn.Models.HelperClasses;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseInterfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers.BaseControllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class BaseController<TModel, TSearch> : ControllerBase
        where TSearch : BaseSearchObject
    {
        protected readonly IService<TModel, TSearch> _service;

        public BaseController(IService<TModel, TSearch> service)
        {
            _service = service;
        }

        /// <summary>The id of the currently authenticated user (from the JWT/Basic auth claims), or null.</summary>
        protected Guid? CurrentUserId =>
            Guid.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : null;

        /// <summary>The role of the currently authenticated user (RoleNames.Admin / "CUSTOMER").</summary>
        protected string? CurrentUserRole => User.FindFirst(ClaimTypes.Role)?.Value;

        protected bool IsAdmin => CurrentUserRole == RoleNames.Admin;

        /// <summary>
        /// Allows the action only if the current user is an admin or is one of the
        /// resource owners. Throws <see cref="ForbiddenException"/> (HTTP 403) otherwise.
        /// Pass multiple ids for resources with more than one legitimate owner (e.g. a
        /// request's sender and receiver).
        /// </summary>
        protected void EnsureOwnerOrAdmin(params Guid[] ownerIds)
        {
            if (IsAdmin) return;
            if (CurrentUserId == null || !ownerIds.Contains(CurrentUserId.Value))
                throw new ForbiddenException();
        }

        [HttpGet]
        public virtual async Task<PagedResult<TModel>> GetList([FromQuery] TSearch search)
        {
            return await _service.GetPagedAsync(search);
        }

        [HttpGet("{id}")]
        public virtual TModel GetById(Guid id)
        {
            return _service.GetById(id);
        }
    }
}
