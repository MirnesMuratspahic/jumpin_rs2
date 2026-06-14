namespace JumpIn.Models.Constants
{
    /// Role names used in authorization. Must match the values issued in the
    /// JWT/Basic auth claims and seeded user roles.
    public static class RoleNames
    {
        public const string Admin = "ADMIN";
        public const string Customer = "CUSTOMER";
    }
}
