namespace JumpIn.Models.Requests
{
    public class ForgotPasswordRequest
    {
        public string Email { get; set; } = "";
    }

    public class ResetPasswordRequest
    {
        public string Email { get; set; } = "";
        public string Code { get; set; } = "";
        public string NewPassword { get; set; } = "";
        public string ConfirmNewPassword { get; set; } = "";
    }
}
