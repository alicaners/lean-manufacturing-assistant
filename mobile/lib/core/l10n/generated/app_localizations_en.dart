// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lean Manufacturing Assistant';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get errorGenericMessage =>
      'The operation could not be completed. Please try again later.';

  @override
  String get emptyGenericMessage => 'Nothing here yet.';

  @override
  String get homeEmptyMessage => 'Screens will appear here soon.';
}
