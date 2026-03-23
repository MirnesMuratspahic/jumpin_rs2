using JumpIn.Models.DTOs;
using JumpIn.Models.Requests;
using JumpIn.Services.Database;
using Mapster;

namespace JumpIn.Services.Mapping
{
    public static class RegisterMappings
    {
        public static void Register()
        {
            // User mappings
            TypeAdapterConfig<User, UserModel>.NewConfig()
                .Map(dest => dest.Status, src => src.Status.ToString().ToUpper())
                .Map(dest => dest.Role, src => src.Role.ToString().ToUpper())
                .Map(dest => dest.AverageRating, src => 0m)
                .Map(dest => dest.TotalReviews, src => 0)
                .Map(dest => dest.TotalAds, src => 0);

            TypeAdapterConfig<UserInsertRequest, User>.NewConfig()
                .Ignore(dest => dest.PasswordHash)
                .Ignore(dest => dest.RegistrationDate)
                .Ignore(dest => dest.Status)
                .Ignore(dest => dest.Role);

            TypeAdapterConfig<UserUpdateRequest, User>.NewConfig()
                .IgnoreNullValues(true)
                .Ignore(dest => dest.PasswordHash);

            // Ad mappings
            TypeAdapterConfig<Ad, AdDTO>.NewConfig()
                .Map(dest => dest.AdType, src => src.AdType.ToString().ToUpper());

            TypeAdapterConfig<AdInsertRequest, Ad>.NewConfig();
            TypeAdapterConfig<AdUpdateRequest, Ad>.NewConfig()
                .IgnoreNullValues(true);

            // Request mappings
            TypeAdapterConfig<RequestInsertRequest, Request>.NewConfig()
                .Ignore(dest => dest.ReceiverId)
                .Ignore(dest => dest.RequestNumber)
                .Ignore(dest => dest.Status)
                .Ignore(dest => dest.CreatedAt);

            // Review mappings
            TypeAdapterConfig<ReviewInsertRequest, Review>.NewConfig()
                .Ignore(dest => dest.CreatedAt);

            TypeAdapterConfig<ReviewUpdateRequest, Review>.NewConfig()
                .IgnoreNullValues(true);

            // Support mappings
            TypeAdapterConfig<SupportInsertRequest, SupportMessage>.NewConfig()
                .Ignore(dest => dest.Status)
                .Ignore(dest => dest.CreatedAt);

            // Payment mappings
            TypeAdapterConfig<Payment, PaymentDTO>.NewConfig()
                .Map(dest => dest.PaymentType, src => src.PaymentType.ToString().ToUpper())
                .Map(dest => dest.Status, src => src.Status.ToString().ToUpper());

            TypeAdapterConfig<PaymentInsertRequest, Payment>.NewConfig()
                .Ignore(dest => dest.Status)
                .Ignore(dest => dest.CreatedAt);

            TypeAdapterConfig<PaymentUpdateRequest, Payment>.NewConfig()
                .IgnoreNullValues(true);

            // Favorite mappings
            TypeAdapterConfig<FavoriteInsertRequest, Favorite>.NewConfig()
                .Ignore(dest => dest.CreatedAt);

            // AdImage mappings
            TypeAdapterConfig<AdImageInsertRequest, AdImage>.NewConfig()
                .Ignore(dest => dest.CreatedAt);

            TypeAdapterConfig<AdImageUpdateRequest, AdImage>.NewConfig()
                .IgnoreNullValues(true);

            // UserPreference mappings
            TypeAdapterConfig<UserPreference, UserPreferenceDTO>.NewConfig()
                .Map(dest => dest.PreferredAdType, src => src.PreferredAdType != null ? src.PreferredAdType.ToString().ToUpper() : null);

            TypeAdapterConfig<UserPreferenceInsertRequest, UserPreference>.NewConfig()
                .Ignore(dest => dest.UpdatedAt);

            TypeAdapterConfig<UserPreferenceUpdateRequest, UserPreference>.NewConfig()
                .IgnoreNullValues(true);

            // ActivityLog mappings
            TypeAdapterConfig<ActivityLog, ActivityLogDTO>.NewConfig()
                .Map(dest => dest.ActivityType, src => src.ActivityType.ToString().ToUpper());

            // City mappings
            TypeAdapterConfig<CityInsertRequest, City>.NewConfig();
            TypeAdapterConfig<CityUpdateRequest, City>.NewConfig()
                .IgnoreNullValues(true);
        }
    }
}
