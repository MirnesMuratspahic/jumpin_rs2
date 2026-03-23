namespace JumpIn.Models.SearchObjects
{
    public class UserSearchObject : BaseSearchObject
    {
        public string? Username { get; set; }
        public string? Email { get; set; }
        public string? Status { get; set; }
        public string? Role { get; set; }
        public bool? IsVip { get; set; }
    }
}
