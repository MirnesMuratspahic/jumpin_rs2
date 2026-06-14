namespace JumpIn.Models.SearchObjects
{
    public class FavoriteSearchObject : BaseSearchObject
    {
        public Guid? UserId { get; set; }
        public Guid? AdId { get; set; }
    }
}
