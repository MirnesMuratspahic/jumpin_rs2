namespace JumpIn.Models.Requests
{
    // Body for declining a request: an optional reason surfaced to the sender.
    public class DeclineRequestRequest
    {
        public string? Reason { get; set; }
    }
}
