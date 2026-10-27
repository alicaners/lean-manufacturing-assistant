import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/theme/app_theme.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';

/// Root widget of the application.
class LeanAssistantApp extends StatelessWidget {
  const LeanAssistantApp({
    super.key,
    required this.router,
    required this.authBloc,
  });

  final GoRouter router;
  final AuthBloc authBloc;

  @override
  Widget build(BuildContext context) {
    // Every page can read the sign-in state with context.read/watch<AuthBloc>().
    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp.router(
        routerConfig: router,
        onGenerateTitle: (context) => context.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        // Turkish first: used when the device language is not supported.
        supportedLocales: const [Locale('tr'), Locale('en')],
      ),
    );
  }
}
