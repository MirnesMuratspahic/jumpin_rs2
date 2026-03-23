class Config {
  static String get apiBaseUrl {
    const url = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:5194/api');
    return url;
  }

  static const int requestTimeout = 30;
  static const int pageSize = 20;
}
