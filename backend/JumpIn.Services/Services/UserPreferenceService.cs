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
    public class UserPreferenceService : BaseCRUDService<UserPreferenceDTO, UserPreferenceSearchObject, UserPreference, UserPreferenceInsertRequest, UserPreferenceUpdateRequest>, IUserPreferenceService
    {
        public UserPreferenceService(JumpInDbContext context) : base(context) { }

        public override async Task<PagedResult<UserPreferenceDTO>> GetPagedAsync(UserPreferenceSearchObject search)
        {
            var query = _context.UserPreferences.AsQueryable();

            query = AddFilter(query, search);
            query = ApplySorting(query, search);

            var totalCount = await query.CountAsync();

            query = query.ApplyPaging(search);

            var list = await query.ToListAsync();
            var result = list.Select(MapToDto).ToList();

            return new PagedResult<UserPreferenceDTO>
            {
                ResultList = result,
                Count = totalCount
            };
        }

        protected override IQueryable<UserPreference> AddFilter(IQueryable<UserPreference> query, UserPreferenceSearchObject search)
        {
            if (search.UserId.HasValue)
                query = query.Where(up => up.UserId == search.UserId.Value);

            if (!string.IsNullOrEmpty(search.PreferredAdType))
            {
                if (Enum.TryParse<AdType>(search.PreferredAdType, true, out var adType))
                    query = query.Where(up => up.PreferredAdType == adType);
            }

            return query;
        }

        protected override void BeforeInsert(UserPreferenceInsertRequest request, UserPreference entity)
        {
            var user = _context.Users.Find(request.UserId);
            if (user == null || user.IsDeleted)
                throw new UserException("User not found.");

            var existing = _context.UserPreferences.FirstOrDefault(up => up.UserId == request.UserId);
            if (existing != null)
                throw new UserException("User preference already exists. Use update instead.");

            entity.UpdatedAt = DateTime.UtcNow;
        }

        protected override void BeforeUpdate(UserPreferenceUpdateRequest request, UserPreference entity)
        {
            entity.UpdatedAt = DateTime.UtcNow;
        }

        private UserPreferenceDTO MapToDto(UserPreference entity)
        {
            var dto = entity.Adapt<UserPreferenceDTO>();
            dto.PreferredAdType = entity.PreferredAdType?.ToString().ToUpper();
            return dto;
        }
    }
}
