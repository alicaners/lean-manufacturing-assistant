import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/app/di/injection.config.dart';
import 'package:lean_assistant/core/config/app_config.dart';

/// Global service locator.
final GetIt getIt = GetIt.instance;

/// Registers the flavor's [config] and every injectable-annotated class.
@InjectableInit(ignoreUnregisteredTypes: [AppConfig])
void configureDependencies(AppConfig config) {
  getIt.registerSingleton<AppConfig>(config);
  getIt.init();
}
