import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/app/router/app_router.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';

/// Registers third-party objects that we cannot annotate directly.
@module
abstract class AppModule {
  @lazySingleton
  GoRouter router(AuthBloc authBloc) => createRouter(authBloc);
}
