import 'package:lean_assistant/app/bootstrap.dart';
import 'package:lean_assistant/core/config/app_config.dart';
import 'package:lean_assistant/firebase_options_prod.dart' as firebase_prod;

/// Production build. The real API address is injected at build time:
///   flutter build apk --flavor prod -t lib/main_prod.dart --dart-define=API_BASE_URL=https://...
Future<void> main() {
  return bootstrap(
    const AppConfig(
      environment: AppEnvironment.prod,
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.lean-assistant.invalid',
      ),
    ),
    firebase_prod.DefaultFirebaseOptions.currentPlatform,
  );
}
