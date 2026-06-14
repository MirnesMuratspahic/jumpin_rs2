using JumpIn.Models.DTOs;
using JumpIn.Models.Enums;
using JumpIn.Models.Exceptions;
using JumpIn.Models.HelperClasses;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseServices;
using JumpIn.Services.Database;
using JumpIn.Services.Interfaces;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace JumpIn.Services.Services
{
    public class PaymentService : BaseCRUDService<PaymentDTO, PaymentSearchObject, Payment, PaymentInsertRequest, PaymentUpdateRequest>, IPaymentService
    {
        public PaymentService(JumpInDbContext context) : base(context) { }

        public override async Task<PagedResult<PaymentDTO>> GetPagedAsync(PaymentSearchObject search)
        {
            var query = _context.Payments
                .Include(p => p.User)
                .AsQueryable();

            query = AddFilter(query, search);
            query = ApplySorting(query, search);

            var totalCount = await query.CountAsync();

            query = query.ApplyPaging(search);

            var list = await query.ToListAsync();
            var result = list.Select(MapToDto).ToList();

            return new PagedResult<PaymentDTO>
            {
                ResultList = result,
                Count = totalCount
            };
        }

        protected override IQueryable<Payment> AddFilter(IQueryable<Payment> query, PaymentSearchObject search)
        {
            if (search.UserId.HasValue)
                query = query.Where(p => p.UserId == search.UserId.Value);

            if (!string.IsNullOrEmpty(search.Status))
            {
                if (Enum.TryParse<PaymentStatus>(search.Status, true, out var status))
                    query = query.Where(p => p.Status == status);
            }

            if (!string.IsNullOrEmpty(search.PaymentType))
            {
                if (Enum.TryParse<PaymentType>(search.PaymentType, true, out var type))
                    query = query.Where(p => p.PaymentType == type);
            }

            if (search.MinAmount.HasValue)
                query = query.Where(p => p.Amount >= search.MinAmount.Value);

            if (search.MaxAmount.HasValue)
                query = query.Where(p => p.Amount <= search.MaxAmount.Value);

            if (search.DateFrom.HasValue)
                query = query.Where(p => p.CreatedAt >= search.DateFrom.Value);

            if (search.DateTo.HasValue)
                query = query.Where(p => p.CreatedAt <= search.DateTo.Value);

            return query;
        }

        protected override void BeforeInsert(PaymentInsertRequest request, Payment entity)
        {
            var user = _context.Users.Find(request.UserId);
            if (user == null || user.IsDeleted)
                throw new UserException("User not found.");

            entity.Status = PaymentStatus.Pending;
            entity.CreatedAt = DateTime.UtcNow;
            if (string.IsNullOrEmpty(entity.Currency))
                entity.Currency = "BAM";
        }

        protected override void BeforeUpdate(PaymentUpdateRequest request, Payment entity)
        {
            if (request.Status.HasValue && request.Status.Value == PaymentStatus.Completed)
                entity.CompletedAt = DateTime.UtcNow;
        }

        private PaymentDTO MapToDto(Payment entity)
        {
            var dto = entity.Adapt<PaymentDTO>();
            dto.PaymentType = entity.PaymentType.ToString().ToUpper();
            dto.Status = entity.Status.ToString().ToUpper();

            if (entity.User != null)
                dto.UserName = $"{entity.User.FirstName} {entity.User.LastName}";

            return dto;
        }
    }
}
