class AppConstants {
  static const String appName = 'LUMI AI';
  static const String backendBaseUrl = 'http://127.0.0.1:3000';
  static const String mockUserId = 'lumi-demo-user';
  static const String mockUserRole = 'student';
  static const int defaultTopK = 5;

  /// Set to false in production. When true and no JWT is stored,
  /// requests fall back to mock headers for local Postman-style testing.
  static const bool mockAuthEnabled = false;

  static const Map<String, String> mockAuthHeaders = {
    'x-mock-user-id': mockUserId,
    'x-mock-user-role': mockUserRole,
  };
}
