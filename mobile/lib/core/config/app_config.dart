/// Which build of the app is running.
enum AppEnvironment { dev, prod }

/// Environment-specific settings, provided by the flavor's entry point.
class AppConfig {
  const AppConfig({required this.environment, required this.apiBaseUrl});

  final AppEnvironment environment;

  /// Base address of the backend API.
  final String apiBaseUrl;

  bool get isProduction => environment == AppEnvironment.prod;
}
