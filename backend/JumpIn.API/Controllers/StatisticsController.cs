using JumpIn.Models.Constants;
using JumpIn.Models.DTOs;
using JumpIn.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JumpIn.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = RoleNames.Admin)]
    public class StatisticsController : ControllerBase
    {
        private readonly IStatisticsService _statisticsService;

        public StatisticsController(IStatisticsService statisticsService)
        {
            _statisticsService = statisticsService;
        }

        [HttpGet]
        public async Task<AdminStatistics> GetAdminStatistics()
        {
            return await _statisticsService.GetAdminStatisticsAsync();
        }
    }
}
