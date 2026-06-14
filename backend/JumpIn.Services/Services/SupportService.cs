using JumpIn.Models.DTOs;
using JumpIn.Models.Enums;
using JumpIn.Models.Exceptions;
using JumpIn.Models.HelperClasses;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseServices;
using JumpIn.Services.Database;
using JumpIn.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace JumpIn.Services.Services
{
    public class SupportService : BaseCRUDService<SupportMessageDTO, SupportSearchObject, SupportMessage, SupportInsertRequest, SupportUpdateRequest>, ISupportService
    {
        public SupportService(JumpInDbContext context) : base(context) { }

        public override async Task<PagedResult<SupportMessageDTO>> GetPagedAsync(SupportSearchObject search)
        {
            var query = _context.SupportMessages
                .Include(s => s.User)
                .Include(s => s.ChatMessages)
                .AsQueryable();

            query = AddFilter(query, search);
            query = ApplySorting(query, search);

            var totalCount = await query.CountAsync();

            query = query.ApplyPaging(search);

            var list = await query.ToListAsync();
            var result = list.Select(MapToDto).ToList();

            return new PagedResult<SupportMessageDTO>
            {
                ResultList = result,
                Count = totalCount
            };
        }

        protected override IQueryable<SupportMessage> AddFilter(IQueryable<SupportMessage> query, SupportSearchObject search)
        {
            if (search.UserId.HasValue)
                query = query.Where(s => s.UserId == search.UserId.Value);

            if (!string.IsNullOrEmpty(search.Status))
            {
                if (Enum.TryParse<SupportStatus>(search.Status, true, out var status))
                    query = query.Where(s => s.Status == status);
            }

            if (!string.IsNullOrEmpty(search.SearchTerm))
            {
                var term = search.SearchTerm.ToLower();
                query = query.Where(s =>
                    s.Subject.ToLower().Contains(term) ||
                    s.Message.ToLower().Contains(term));
            }

            return query;
        }

        public override SupportMessageDTO Insert(SupportInsertRequest request)
        {
            var user = _context.Users.Find(request.UserId);
            if (user == null || user.IsDeleted)
                throw new UserException("User not found.");

            // Creating/reusing the conversation and appending the chat can be two
            // saves — commit them atomically.
            using var tx = _context.Database.BeginTransaction();

            var now = DateTime.UtcNow;

            // One conversation per user: reuse the existing ticket if there is one,
            // otherwise create it. New user messages always append as chat messages.
            var conversation = _context.SupportMessages
                .Where(s => s.UserId == request.UserId)
                .OrderBy(s => s.CreatedAt)
                .FirstOrDefault();

            if (conversation == null)
            {
                conversation = new SupportMessage
                {
                    Id = Guid.NewGuid(),
                    UserId = request.UserId,
                    Subject = request.Subject,
                    Message = request.Message,
                    Status = SupportStatus.Open,
                    CreatedAt = now
                };
                _context.SupportMessages.Add(conversation);
                _context.SaveChanges();
            }
            else
            {
                // Backfill the original message as the first chat bubble if this
                // conversation predates the chat thread (e.g. seeded tickets).
                var hasChats = _context.SupportChats.Any(c => c.SupportMessageId == conversation.Id);
                if (!hasChats)
                {
                    _context.SupportChats.Add(new SupportChat
                    {
                        Id = Guid.NewGuid(),
                        SupportMessageId = conversation.Id,
                        Message = conversation.Message,
                        IsAdminMessage = false,
                        CreatedAt = conversation.CreatedAt
                    });
                }

                conversation.Message = request.Message;
                conversation.Status = SupportStatus.Open;
            }

            _context.SupportChats.Add(new SupportChat
            {
                Id = Guid.NewGuid(),
                SupportMessageId = conversation.Id,
                Message = request.Message,
                IsAdminMessage = false,
                CreatedAt = now
            });

            _context.SaveChanges();
            tx.Commit();

            var saved = _context.SupportMessages
                .Include(s => s.User)
                .Include(s => s.ChatMessages)
                .First(s => s.Id == conversation.Id);

            return MapToDto(saved);
        }

        public override SupportMessageDTO Update(Guid id, SupportUpdateRequest request)
        {
            var entity = _context.SupportMessages.Include(s => s.User).FirstOrDefault(s => s.Id == id);
            if (entity == null)
                throw new UserException("Support message not found.");

            if (!string.IsNullOrEmpty(request.Response))
            {
                entity.Response = request.Response;
                entity.RespondedAt = DateTime.UtcNow;
            }

            if (!string.IsNullOrEmpty(request.Status))
            {
                if (Enum.TryParse<SupportStatus>(request.Status, true, out var status))
                    entity.Status = status;
            }

            _context.SaveChanges();
            return MapToDto(entity);
        }

        public override SupportMessageDTO GetById(Guid id)
        {
            var entity = _context.SupportMessages
                .Include(s => s.User)
                .Include(s => s.ChatMessages)
                .FirstOrDefault(s => s.Id == id);

            if (entity == null)
                throw new UserException("Support message not found.");

            return MapToDto(entity);
        }

        public SupportMessageDTO RespondToMessage(Guid id, string response)
        {
            if (string.IsNullOrWhiteSpace(response))
                throw new UserException("Response cannot be empty.");

            var now = DateTime.UtcNow;

            var chatCount = _context.SupportChats.Count(c => c.SupportMessageId == id);

            if (chatCount == 0)
            {
                var entity = _context.SupportMessages.FirstOrDefault(s => s.Id == id);
                if (entity == null)
                    throw new UserException("Support message not found.");

                _context.SupportChats.Add(new SupportChat
                {
                    Id = Guid.NewGuid(),
                    SupportMessageId = id,
                    Message = entity.Message,
                    IsAdminMessage = false,
                    CreatedAt = entity.CreatedAt
                });
            }

            _context.SupportChats.Add(new SupportChat
            {
                Id = Guid.NewGuid(),
                SupportMessageId = id,
                Message = response,
                IsAdminMessage = true,
                CreatedAt = now
            });

            var supportMessage = _context.SupportMessages.FirstOrDefault(s => s.Id == id);
            if (supportMessage == null)
                throw new UserException("Support message not found.");

            supportMessage.Response = response;
            supportMessage.RespondedAt = now;
            supportMessage.Status = SupportStatus.InProgress;

            _context.SaveChanges();

            var updatedEntity = _context.SupportMessages
                .Include(s => s.User)
                .Include(s => s.ChatMessages)
                .FirstOrDefault(s => s.Id == id);

            return MapToDto(updatedEntity);
        }

        private SupportMessageDTO MapToDto(SupportMessage entity)
        {
            var chatMessages = entity.ChatMessages
                .OrderBy(cm => cm.CreatedAt)
                .Select(cm => new ChatMessageDTO
                {
                    Id = cm.Id,
                    Message = cm.Message,
                    IsAdminMessage = cm.IsAdminMessage,
                    CreatedAt = cm.CreatedAt
                })
                .ToList();

            return new SupportMessageDTO
            {
                Id = entity.Id,
                Subject = entity.Subject,
                Message = entity.Message,
                AdminResponse = entity.Response,
                Status = entity.Status.ToString().ToUpper(),
                CreatedAt = entity.CreatedAt,
                RespondedAt = entity.RespondedAt,
                UserId = entity.UserId,
                UserUsername = entity.User != null ? $"{entity.User.FirstName} {entity.User.LastName}" : null,
                UserEmail = entity.User?.Email,
                ChatMessages = chatMessages
            };
        }
    }
}
