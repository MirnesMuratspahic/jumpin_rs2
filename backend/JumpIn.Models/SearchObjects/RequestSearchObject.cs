namespace JumpIn.Models.SearchObjects
{
    public class RequestSearchObject : BaseSearchObject
    {
        public Guid? SenderId { get; set; }
        public Guid? ReceiverId { get; set; }
        public Guid? AdId { get; set; }
        public string? Status { get; set; }
        public string? AdType { get; set; }

        // Server-enforced scope: limits results to requests where the user is either
        // sender OR receiver. Set from the JWT for non-admins, never by the client.
        public Guid? InvolvedUserId { get; set; }
    }
}
