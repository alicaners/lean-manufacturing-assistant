import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/theme/app_theme.dart';

extension PumpApp on WidgetTester {
  /// Pumps [widget] inside a MaterialApp with theme and Turkish translations.
  Future<void> pumpApp(Widget widget) {
    return pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(body: widget),
      ),
    );
  }
}
