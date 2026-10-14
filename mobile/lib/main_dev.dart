import 'package:lean_assistant/app/bootstrap.dart';
import 'package:lean_assistant/core/config/app_config.dart';

/// Development build: talks to the backend running on this computer.
/// 10.0.2.2 is the host computer as seen from the Android emulator.
void main() {
  bootstrap(
    const AppConfig(
      environment: AppEnvironment.dev,
      apiBaseUrl: 'http://10.0.2.2:5069',
    ),
  );
}
