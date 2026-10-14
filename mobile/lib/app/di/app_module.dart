import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/app/router/app_router.dart';
import 'package:lean_assistant/core/config/app_config.dart';

/// Registers third-party objects that we cannot annotate directly.
@module
abstract class AppModule {
  @lazySingleton
  GoRouter get router => createRouter();

  /// Temporary: replaced by flavor-specific values in the next part.
  /// 10.0.2.2 is the host computer as seen from the Android emulator.
  @singleton
  AppConfig get config => const AppConfig(apiBaseUrl: 'http://10.0.2.2:5069');
}
