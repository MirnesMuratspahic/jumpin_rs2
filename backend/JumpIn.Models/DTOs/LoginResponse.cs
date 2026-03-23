namespace JumpIn.Models.DTOs
{
    public class LoginResponse
    {
        public UserModel User { get; set; }
        public string Token { get; set; }
    }
}
