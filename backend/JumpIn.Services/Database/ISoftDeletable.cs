namespace JumpIn.Services.Database
{
    public interface ISoftDeletable
    {
        bool IsDeleted { get; set; }
        DateTime? DeleteTime { get; set; }
    }
}
