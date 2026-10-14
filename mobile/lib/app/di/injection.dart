import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/app/di/injection.config.dart';

/// Global service locator.
final GetIt getIt = GetIt.instance;

/// Registers every class annotated with injectable annotations.
/// The registration code is generated into `injection.config.dart`.
@InjectableInit()
void configureDependencies() => getIt.init();
