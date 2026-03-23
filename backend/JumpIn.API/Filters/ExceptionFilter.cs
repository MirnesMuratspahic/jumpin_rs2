using JumpIn.Models.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace JumpIn.API.Filters
{
    public class ExceptionFilter : ExceptionFilterAttribute
    {
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
            else
            {
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
