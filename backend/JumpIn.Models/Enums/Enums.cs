namespace JumpIn.Models.Enums
{
    public enum UserStatus
    {
        Active,
        Blocked
    }

    public enum UserRole
    {
        Admin,
        Customer
    }

    public enum AdType
    {
        Route,
        Car,
        Apartment
    }

    public enum RequestStatus
    {
        Pending,
        Accepted,
        Declined
    }

    public enum SupportStatus
    {
        Open,
        InProgress,
        Resolved
    }

    public enum PaymentType
    {
        VipSubscription,
        AdPromotion,
        Reservation
    }

    public enum PaymentStatus
    {
        Pending,
        Completed,
        Failed,
        Refunded
    }

    public enum ActivityType
    {
        Login,
        AdCreated,
        AdUpdated,
        RequestSent,
        RequestAccepted,
        RequestDeclined,
        ReviewLeft,
        FavoriteAdded,
        ProfileUpdated,
        VipActivated
    }
}
