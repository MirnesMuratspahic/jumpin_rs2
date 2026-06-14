using JumpIn.Models.DTOs;
using JumpIn.Models.Enums;
using JumpIn.Models.Exceptions;
using JumpIn.Models.HelperClasses;
using JumpIn.Models.Messages;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseServices;
using JumpIn.Services.Database;
using JumpIn.Services.Interfaces;
using Mapster;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace JumpIn.Services.Services
{
    public class RequestService : BaseCRUDService<RequestDTO, RequestSearchObject, Request, RequestInsertRequest, RequestUpdateRequest>, IRequestService
    {
        private readonly IMessagePublisher _messagePublisher;
        private readonly ILogger<RequestService> _logger;
        private readonly INotificationService _notificationService;

        public RequestService(JumpInDbContext context, IMessagePublisher messagePublisher, ILogger<RequestService> logger, INotificationService notificationService) : base(context)
        {
            _messagePublisher = messagePublisher;
            _logger = logger;
            _notificationService = notificationService;
        }

        public override async Task<PagedResult<RequestDTO>> GetPagedAsync(RequestSearchObject search)
        {
            var query = _context.Requests
                .Include(r => r.Sender)
                .Include(r => r.Receiver)
                .Include(r => r.Ad)
                .Where(r => !r.IsDeleted)
                .AsQueryable();

            query = AddFilter(query, search);
            query = ApplySorting(query, search);

            var totalCount = await query.CountAsync();

            query = query.ApplyPaging(search);

            var list = await query.ToListAsync();
            var result = list.Select(MapToDto).ToList();

            return new PagedResult<RequestDTO>
            {
                ResultList = result,
                Count = totalCount
            };
        }

        public override RequestDTO GetById(Guid id)
        {
            var entity = _context.Requests
                .Include(r => r.Sender)
                .Include(r => r.Receiver)
                .Include(r => r.Ad)
                .FirstOrDefault(r => r.Id == id && !r.IsDeleted);

            if (entity == null)
                throw new UserException("Request not found.");

            return MapToDto(entity);
        }

        protected override IQueryable<Request> AddFilter(IQueryable<Request> query, RequestSearchObject search)
        {
            if (search.SenderId.HasValue)
                query = query.Where(r => r.SenderId == search.SenderId.Value);

            if (search.ReceiverId.HasValue)
                query = query.Where(r => r.ReceiverId == search.ReceiverId.Value);

            if (search.AdId.HasValue)
                query = query.Where(r => r.AdId == search.AdId.Value);

            if (!string.IsNullOrEmpty(search.Status))
            {
                if (Enum.TryParse<RequestStatus>(search.Status, true, out var status))
                    query = query.Where(r => r.Status == status);
            }

            if (!string.IsNullOrEmpty(search.AdType))
            {
                if (Enum.TryParse<AdType>(search.AdType, true, out var adType))
                    query = query.Where(r => r.Ad.AdType == adType);
            }

            return query;
        }

        protected override void BeforeInsert(RequestInsertRequest request, Request entity)
        {
            var sender = _context.Users.Find(request.SenderId);
            if (sender == null || sender.IsDeleted)
                throw new UserException("Sender not found.");

            var ad = _context.Ads.Include(a => a.User).FirstOrDefault(a => a.Id == request.AdId && !a.IsDeleted);
            if (ad == null)
                throw new UserException("Ad not found.");

            if (ad.UserId == request.SenderId)
                throw new UserException("You cannot send a request for your own ad.");

            var existingRequest = _context.Requests.Any(r =>
                r.SenderId == request.SenderId &&
                r.AdId == request.AdId &&
                r.Status == RequestStatus.Pending &&
                !r.IsDeleted);

            if (existingRequest)
                throw new UserException("You already have a pending request for this ad.");

            entity.ReceiverId = ad.UserId;
            entity.SenderEmail = sender.Email;
            entity.ReceiverEmail = ad.User?.Email;
            entity.RequestNumber = GenerateRequestNumber();
            entity.Status = RequestStatus.Pending;
            entity.CreatedAt = DateTime.UtcNow;
        }

        protected override void AfterInsert(RequestInsertRequest request, Request entity)
        {
            try
            {
                var ad = _context.Ads.Include(a => a.User).FirstOrDefault(a => a.Id == entity.AdId);
                var sender = _context.Users.Find(entity.SenderId);

                if (ad?.User != null && sender != null)
                {
                    // Persisted in-app notification for the ad owner (DB, synchronous).
                    _notificationService.Create(
                        ad.UserId,
                        "New request",
                        $"{sender.FirstName} {sender.LastName} sent a request for your ad '{ad.Title}'.",
                        "REQUEST_CREATED");

                    // Queue the broker notification + email (best-effort, async).
                    var senderName = $"{sender.FirstName} {sender.LastName}";
                    _ = PublishRequestMessagesAsync(ad.UserId, ad.User.Email, ad.Title, senderName);
                }
            }
            catch (Exception ex)
            {
                // Notification/email is best-effort; the request itself is already saved.
                _logger.LogError(ex, "Failed to queue notification/email after creating request {RequestId}.", entity.Id);
            }
        }

        private async Task PublishRequestMessagesAsync(Guid ownerId, string ownerEmail, string adTitle, string senderName)
        {
            try
            {
                await _messagePublisher.PublishNotificationAsync(new NotificationMessage
                {
                    UserId = ownerId,
                    Title = "New Request",
                    Body = $"{senderName} sent a request for your ad '{adTitle}'.",
                    Type = "REQUEST_CREATED"
                });

                await _messagePublisher.PublishEmailAsync(new EmailMessage
                {
                    To = ownerEmail,
                    Subject = $"New request for your ad: {adTitle}",
                    Body = $"<h2>New Request Received</h2><p>{senderName} has sent a request for your ad '<strong>{adTitle}</strong>'.</p><p>Log in to JumpIn to respond.</p>"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish notification/email for ad '{AdTitle}'.", adTitle);
            }
        }

        public async Task<RequestDTO> AcceptRequestAsync(Guid id)
        {
            var entity = await _context.Requests
                .Include(r => r.Sender)
                .Include(r => r.Receiver)
                .Include(r => r.Ad)
                .FirstOrDefaultAsync(r => r.Id == id && !r.IsDeleted);

            if (entity == null)
                throw new UserException("Request not found.");

            if (entity.Status != RequestStatus.Pending)
                throw new UserException("Only pending requests can be accepted.");

            entity.Status = RequestStatus.Accepted;
            entity.RespondedAt = DateTime.UtcNow;

            // Deactivate the ad after accepting a request
            if (entity.Ad != null)
            {
                entity.Ad.IsActive = false;
            }

            await _context.SaveChangesAsync();

            await _notificationService.CreateAsync(
                entity.SenderId,
                "Request accepted",
                $"Your request for '{entity.Ad?.Title}' was accepted.",
                "REQUEST_ACCEPTED");

            return MapToDto(entity);
        }

        public async Task<RequestDTO> DeclineRequestAsync(Guid id)
        {
            var entity = await _context.Requests
                .Include(r => r.Sender)
                .Include(r => r.Receiver)
                .Include(r => r.Ad)
                .FirstOrDefaultAsync(r => r.Id == id && !r.IsDeleted);

            if (entity == null)
                throw new UserException("Request not found.");

            if (entity.Status != RequestStatus.Pending)
                throw new UserException("Only pending requests can be declined.");

            entity.Status = RequestStatus.Declined;
            entity.RespondedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            await _notificationService.CreateAsync(
                entity.SenderId,
                "Request declined",
                $"Your request for '{entity.Ad?.Title}' was declined.",
                "REQUEST_DECLINED");

            return MapToDto(entity);
        }

        private string GenerateRequestNumber()
        {
            return $"REQ-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..6].ToUpper()}";
        }

        private RequestDTO MapToDto(Request entity)
        {
            var dto = new RequestDTO
            {
                Id = entity.Id,
                RequestNumber = entity.RequestNumber,
                SenderId = entity.SenderId,
                SenderName = entity.Sender != null ? $"{entity.Sender.FirstName} {entity.Sender.LastName}" : null,
                SenderEmail = entity.SenderEmail,
                SenderPhone = entity.Sender?.Phone,
                SenderProfileImage = entity.Sender?.ProfileImageUrl,
                ReceiverId = entity.ReceiverId,
                ReceiverName = entity.Receiver != null ? $"{entity.Receiver.FirstName} {entity.Receiver.LastName}" : null,
                ReceiverEmail = entity.ReceiverEmail,
                ReceiverPhone = entity.Receiver?.Phone,
                AdId = entity.AdId,
                AdTitle = entity.Ad?.Title,
                AdType = entity.Ad?.AdType.ToString().ToUpper(),
                Status = entity.Status.ToString().ToUpper(),
                Message = entity.Message,
                CreatedAt = entity.CreatedAt,
                RespondedAt = entity.RespondedAt
            };

            return dto;
        }
    }
}
