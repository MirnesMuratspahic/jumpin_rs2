namespace JumpIn.Models.Requests
{
    // Body for confirming the SMS phone-verification code.
    public class VerifyPhoneRequest
    {
        public string? Code { get; set; }
    }
}
