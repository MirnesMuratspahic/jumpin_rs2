class Config {
  static String get apiBaseUrl {
    const url = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:5194/api');
    return url;
  }

  /// Google Maps / Directions API key. Injected at build time via
  /// `--dart-define=GOOGLE_MAPS_API_KEY=...` rather than hardcoded in source.
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const int requestTimeout = 30;
  static const int pageSize = 20;
}
