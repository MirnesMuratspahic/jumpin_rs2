using JumpIn.API.Controllers.BaseControllers;
using JumpIn.Models.DTOs;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReviewController : BaseCRUDController<ReviewDTO, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
        private readonly IReviewService _reviewService;

        public ReviewController(IReviewService service) : base(service)
        {
            _reviewService = service;
        }

        [HttpGet("user/{userId}")]
        public List<ReviewDTO> GetReviewsByUser(Guid userId)
        {
            return _reviewService.GetReviewsByUser(userId);
        }

        public override ReviewDTO Insert([FromBody] ReviewInsertRequest request)
        {
            // Reviewer always comes from the authenticated user, never the request body.
            if (CurrentUserId != null) request.ReviewerId = CurrentUserId.Value;
            return _service.Insert(request);
        }

        [Authorize]
        [HttpPost("create-for-user/{reviewedUserId}")]
        public ReviewDTO CreateReviewForUser(Guid reviewedUserId, [FromBody] ReviewInsertRequest request)
        {
            if (CurrentUserId != null) request.ReviewerId = CurrentUserId.Value;
            return _reviewService.CreateReviewForUser(reviewedUserId, request);
        }

        public override ReviewDTO Update(Guid id, [FromBody] ReviewUpdateRequest request)
        {
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.ReviewerId);
            return _service.Update(id, request);
        }

        public override ReviewDTO Delete(Guid id)
        {
            var existing = _service.GetById(id);
            EnsureOwnerOrAdmin(existing.ReviewerId);
            return _service.Delete(id);
        }
    }
}
