namespace JumpIn.Models.Requests
{
    public class FavoriteInsertRequest
    {
        public Guid UserId { get; set; }
        public Guid AdId { get; set; }
    }
}
