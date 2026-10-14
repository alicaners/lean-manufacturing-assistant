import 'package:flutter/material.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/theme/app_theme.dart';
import 'package:lean_assistant/features/dashboard/presentation/home_page.dart';

/// Root widget of the application.
class LeanAssistantApp extends StatelessWidget {
  const LeanAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Turkish first: used when the device language is not supported.
      supportedLocales: const [Locale('tr'), Locale('en')],
      home: const HomePage(),
    );
  }
}
