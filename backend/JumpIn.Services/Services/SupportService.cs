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
                .AsQueryable();

            query = AddFilter(query, search);
            query = ApplySorting(query, search);

            var totalCount = await query.CountAsync();

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value)
                             .Take(search.PageSize.Value);
            }

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

        protected override void BeforeInsert(SupportInsertRequest request, SupportMessage entity)
        {
            var user = _context.Users.Find(request.UserId);
            if (user == null || user.IsDeleted)
                throw new UserException("User not found.");

            entity.Status = SupportStatus.Open;
            entity.CreatedAt = DateTime.UtcNow;
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

        public SupportMessageDTO RespondToMessage(Guid id, string response)
        {
            if (string.IsNullOrWhiteSpace(response))
                throw new UserException("Response cannot be empty.");

            var entity = _context.SupportMessages.Include(s => s.User).FirstOrDefault(s => s.Id == id);
            if (entity == null)
                throw new UserException("Support message not found.");

            entity.Response = response;
            entity.RespondedAt = DateTime.UtcNow;
            entity.Status = SupportStatus.InProgress;

            _context.SaveChanges();
            return MapToDto(entity);
        }

        private SupportMessageDTO MapToDto(SupportMessage entity)
        {
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
                UserEmail = entity.User?.Email
            };
        }
    }
}
