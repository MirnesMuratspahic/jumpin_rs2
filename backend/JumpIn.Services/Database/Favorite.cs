namespace JumpIn.Services.Database
{
    public class Favorite
    {
        public Guid Id { get; set; }
        public DateTime CreatedAt { get; set; }

        // Foreign keys
        public Guid UserId { get; set; }
        public virtual User User { get; set; }

        public Guid AdId { get; set; }
        public virtual Ad Ad { get; set; }
    }
}
