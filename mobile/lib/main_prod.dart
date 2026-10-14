import 'package:lean_assistant/app/bootstrap.dart';
import 'package:lean_assistant/core/config/app_config.dart';

/// Production build. The real API address is injected at build time:
///   flutter build apk --flavor prod -t lib/main_prod.dart --dart-define=API_BASE_URL=https://...
void main() {
  bootstrap(
    const AppConfig(
      environment: AppEnvironment.prod,
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.lean-assistant.invalid',
      ),
    ),
  );
}
