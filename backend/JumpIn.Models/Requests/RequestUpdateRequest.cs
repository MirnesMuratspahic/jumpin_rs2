namespace JumpIn.Models.Requests
{
    // Request status is part of the business flow and is changed ONLY through the
    // dedicated accept/decline actions — never via a generic update. This DTO is
    // intentionally empty (no editable fields exposed through the generic PUT).
    public class RequestUpdateRequest
    {
    }
}
