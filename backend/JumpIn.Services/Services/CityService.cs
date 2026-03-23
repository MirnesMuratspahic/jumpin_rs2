using JumpIn.Models.DTOs;
using JumpIn.Models.Requests;
using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseServices;
using JumpIn.Services.Database;
using JumpIn.Services.Interfaces;

namespace JumpIn.Services.Services
{
    public class CityService : BaseCRUDService<CityDTO, CitySearchObject, City, CityInsertRequest, CityUpdateRequest>, ICityService
    {
        public CityService(JumpInDbContext context) : base(context) { }

        protected override IQueryable<City> AddFilter(IQueryable<City> query, CitySearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
            {
                var name = search.Name.ToLower();
                query = query.Where(c => c.Name.ToLower().Contains(name));
            }

            return query;
        }
    }
}
