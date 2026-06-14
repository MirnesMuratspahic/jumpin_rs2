namespace JumpIn.API.Helpers
{
    /// Validates uploaded images by extension, size AND magic bytes (content
    /// sniffing) so a non-image file can't be uploaded by faking the extension.
    public static class ImageFileValidator
    {
        public const long MaxBytes = 10 * 1024 * 1024; // 10 MB
        private static readonly string[] AllowedExtensions = { ".jpg", ".jpeg", ".png", ".webp" };

        public static (bool Ok, string? Error) Validate(IFormFile? file)
        {
            if (file == null || file.Length == 0)
                return (false, "No file provided.");
            if (file.Length > MaxBytes)
                return (false, "File size must be under 10MB.");

            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!AllowedExtensions.Contains(ext))
                return (false, "Only JPG, PNG, and WEBP images are allowed.");

            var header = new byte[12];
            using (var stream = file.OpenReadStream())
            {
                var read = stream.Read(header, 0, header.Length);
                if (read < 12)
                    return (false, "The file is not a valid image.");
            }

            if (!IsJpeg(header) && !IsPng(header) && !IsWebp(header))
                return (false, "The file content is not a valid image.");

            return (true, null);
        }

        private static bool IsJpeg(byte[] h) => h[0] == 0xFF && h[1] == 0xD8 && h[2] == 0xFF;

        private static bool IsPng(byte[] h) =>
            h[0] == 0x89 && h[1] == 0x50 && h[2] == 0x4E && h[3] == 0x47 &&
            h[4] == 0x0D && h[5] == 0x0A && h[6] == 0x1A && h[7] == 0x0A;

        // RIFF....WEBP
        private static bool IsWebp(byte[] h) =>
            h[0] == 0x52 && h[1] == 0x49 && h[2] == 0x46 && h[3] == 0x46 &&
            h[8] == 0x57 && h[9] == 0x45 && h[10] == 0x42 && h[11] == 0x50;
    }
}
