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

  @override
  String get homeGoToLogin => 'Open sign-in screen';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginComingSoon => 'The sign-in screen will appear here soon.';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundMessage => 'The page you are looking for does not exist.';

  @override
  String get commonGoHome => 'Go to home';

  @override
  String get errorNetwork =>
      'Cannot reach the server. Check your internet connection.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorForbidden => 'You do not have permission to do this.';

  @override
  String get errorNotFound => 'The record could not be found.';

  @override
  String get errorConflict =>
      'Someone else changed this record. Please check its latest state.';

  @override
  String get errorValidation => 'Please check the highlighted fields.';

  @override
  String get serverStatusTitle => 'Server connection';

  @override
  String get serverStatusChecking => 'Checking…';

  @override
  String get serverStatusOnline => 'Connected';

  @override
  String get serverStatusDegraded =>
      'Connected, some services are running slowly';

  @override
  String get serverStatusRefresh => 'Check again';
}
