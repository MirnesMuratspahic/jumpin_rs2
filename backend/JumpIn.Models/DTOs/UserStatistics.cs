namespace JumpIn.Models.DTOs
{
    public class UserStatistics
    {
        public int TotalAds { get; set; }
        public int ActiveAds { get; set; }
        public int TotalRequestsSent { get; set; }
        public int TotalRequestsReceived { get; set; }
        public int AcceptedRequests { get; set; }
        public int DeclinedRequests { get; set; }
        public int TotalReviewsGiven { get; set; }
        public int TotalReviewsReceived { get; set; }
        public decimal AverageRating { get; set; }
        public bool IsVip { get; set; }
    }

    public class AdminStatistics
    {
        public int TotalUsers { get; set; }
        public int ActiveUsers { get; set; }
        public int BlockedUsers { get; set; }
        public int VipUsers { get; set; }
        public int TotalAds { get; set; }
        public int RouteAds { get; set; }
        public int CarAds { get; set; }
        public int ApartmentAds { get; set; }
        public int TotalRequests { get; set; }
        public int PendingRequests { get; set; }
        public int AcceptedRequests { get; set; }
        public int DeclinedRequests { get; set; }
        public int TotalReviews { get; set; }
        public int TotalSupportMessages { get; set; }
        public int OpenSupportMessages { get; set; }

        // Derived metrics for the dashboard charts
        public int NewUsersThisMonth { get; set; }
        public double AverageRating { get; set; }
        public double SupportResponseRate { get; set; }
        public double AdCompletionRate { get; set; }
        public double RequestAcceptRate { get; set; }
        public Dictionary<string, int> AdsByType { get; set; } = new();
        public Dictionary<string, int> RequestsByStatus { get; set; } = new();
    }
}
