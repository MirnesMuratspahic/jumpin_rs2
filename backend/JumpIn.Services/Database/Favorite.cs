namespace JumpIn.Services.Database
{
    public class Favorite
    {
        public int Id { get; set; }
        public DateTime CreatedAt { get; set; }

        // Foreign keys
        public int UserId { get; set; }
        public virtual User User { get; set; }

        public int AdId { get; set; }
        public virtual Ad Ad { get; set; }
    }
}
