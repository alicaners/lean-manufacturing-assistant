import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/app.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/core/config/app_config.dart';

/// Shared startup for every flavor.
void bootstrap(AppConfig config) {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies(config);

  final Widget app = LeanAssistantApp(router: getIt<GoRouter>());

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
