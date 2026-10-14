/// Environment-specific settings. Values come from the active flavor.
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  /// Base address of the backend API, e.g. `http://10.0.2.2:5069`.
  final String apiBaseUrl;
}
