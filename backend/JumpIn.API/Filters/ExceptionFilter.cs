using JumpIn.Models.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Logging;

namespace JumpIn.API.Filters
{
    public class ExceptionFilter : ExceptionFilterAttribute
    {
        private readonly ILogger<ExceptionFilter> _logger;

        public ExceptionFilter(ILogger<ExceptionFilter> logger)
        {
            _logger = logger;
        }

        public override void OnException(ExceptionContext context)
        {
            if (context.Exception is UserException userException)
            {
                context.Result = new BadRequestObjectResult(new
                {
                    errors = new Dictionary<string, string[]>
                    {
                        { "UserError", new[] { userException.Message } }
                    }
                });
            }
            else if (context.Exception is ForbiddenException forbiddenException)
            {
                context.Result = new ObjectResult(new
                {
                    errors = new Dictionary<string, string[]>
                    {
                        { "Forbidden", new[] { forbiddenException.Message } }
                    }
                })
                {
                    StatusCode = 403
                };
            }
            else
            {
                // Log the full exception server-side; the client only gets a
                // standardized message (never a stack trace).
                _logger.LogError(context.Exception,
                    "Unhandled exception during {Path}",
                    context.HttpContext.Request.Path);

                context.Result = new ObjectResult(new
                {
                    errors = new Dictionary<string, string[]>
                    {
                        { "ServerError", new[] { "An internal server error occurred." } }
                    }
                })
                {
                    StatusCode = 500
                };
            }

            context.ExceptionHandled = true;
        }
    }
}
