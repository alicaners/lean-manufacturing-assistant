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
  String get loginTitle => 'Sign in';

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

  @override
  String get splashChecking => 'Checking your session…';

  @override
  String homeWelcome(String name) {
    return 'Welcome, $name';
  }

  @override
  String get homeSignOut => 'Sign out';

  @override
  String get loginSubtitle => 'Sign in with your account to continue.';

  @override
  String get loginUserName => 'User name';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginInvalidCredentials =>
      'The user name or password is incorrect.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get errorRateLimited =>
      'Too many attempts. Please try again in a minute.';

  @override
  String get changePasswordTitle => 'Change your password';

  @override
  String get changePasswordRequiredInfo =>
      'An administrator set your password. Choose your own password to continue.';

  @override
  String get changePasswordCurrent => 'Current password';

  @override
  String get changePasswordNew => 'New password';

  @override
  String get changePasswordConfirm => 'New password (again)';

  @override
  String get changePasswordSubmit => 'Change password';

  @override
  String changePasswordTooShort(int min) {
    return 'The password must be at least $min characters.';
  }

  @override
  String get changePasswordSameAsCurrent =>
      'The new password must differ from the current one.';

  @override
  String get changePasswordMismatch => 'The passwords do not match.';

  @override
  String get changePasswordWrongCurrent => 'The current password is incorrect.';
}
