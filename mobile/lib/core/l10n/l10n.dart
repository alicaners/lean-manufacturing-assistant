import 'package:flutter/widgets.dart';
import 'package:lean_assistant/core/l10n/generated/app_localizations.dart';

export 'package:lean_assistant/core/l10n/generated/app_localizations.dart';

/// Short access to translations: `context.l10n.appTitle`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
