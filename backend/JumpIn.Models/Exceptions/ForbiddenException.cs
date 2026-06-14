namespace JumpIn.Models.Exceptions
{
    /// <summary>
    /// Thrown when an authenticated user tries to access or modify a resource
    /// they do not own (and is not an admin). Mapped to HTTP 403 by the API.
    /// </summary>
    public class ForbiddenException : Exception
    {
        public ForbiddenException(string message = "You are not allowed to perform this action.") : base(message) { }
    }
}
