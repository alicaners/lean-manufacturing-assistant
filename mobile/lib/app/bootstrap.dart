import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/app.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/core/config/app_config.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';

/// Shared startup for every flavor.
Future<void> bootstrap(
  AppConfig config,
  FirebaseOptions firebaseOptions,
) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: firebaseOptions);
  if (kDebugMode) {
    debugPrint('Firebase connected: ${Firebase.app().options.appId}');
  }

  configureDependencies(config);

  // Start checking the stored session right away; the splash page waits for it.
  final authBloc = getIt<AuthBloc>()..add(const AuthCheckRequested());

  final Widget app = LeanAssistantApp(
    router: getIt<GoRouter>(),
    authBloc: authBloc,
  );

  runApp(
    config.isProduction
        ? app
        : Directionality(
            textDirection: TextDirection.ltr,
            child: Banner(
              message: config.environment.name.toUpperCase(),
              location: BannerLocation.topEnd,
              child: app,
            ),
          ),
  );
}
