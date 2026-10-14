import 'package:lean_assistant/app/bootstrap.dart';
import 'package:lean_assistant/core/config/app_config.dart';
import 'package:lean_assistant/firebase_options_dev.dart' as firebase_dev;

/// Development build: talks to the backend running on this computer.
/// 10.0.2.2 is the host computer as seen from the Android emulator.
Future<void> main() {
  return bootstrap(
    const AppConfig(
      environment: AppEnvironment.dev,
      apiBaseUrl: 'http://10.0.2.2:5069',
    ),
    firebase_dev.DefaultFirebaseOptions.currentPlatform,
  );
}
