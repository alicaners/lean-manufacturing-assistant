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

  @override
  String get forbiddenTitle => 'You cannot open this page';

  @override
  String get forbiddenMessage =>
      'This page is not available for your role. Contact your administrator if you need it.';

  @override
  String homeRole(String role) {
    return 'Your role: $role';
  }

  @override
  String get homeManageUsers => 'Manage users';

  @override
  String get roleOperator => 'Operator';

  @override
  String get roleSupervisor => 'Supervisor';

  @override
  String get roleTechnician => 'Maintenance technician';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get usersTitle => 'Users';

  @override
  String get usersSearchHint => 'Search by name or user name';

  @override
  String get usersAll => 'All';

  @override
  String get usersActive => 'Active';

  @override
  String get usersInactive => 'Inactive';

  @override
  String get usersAllRoles => 'All roles';

  @override
  String get usersEmpty => 'No users match these filters.';

  @override
  String get usersTemporaryPassword =>
      'Temporary password: changed at first sign-in';

  @override
  String get usersNew => 'New user';

  @override
  String get usersCreated => 'User created.';

  @override
  String get userFormFullName => 'Full name';

  @override
  String get userFormTemporaryPassword => 'Temporary password';

  @override
  String get userFormPasswordInfo =>
      'The user replaces this password with their own at first sign-in. Share it with them in a safe way.';

  @override
  String get userFormRole => 'Role';

  @override
  String get userFormPlant => 'Plant';

  @override
  String get userFormAllPlants => 'All plants (system admin)';

  @override
  String get userFormLine => 'Line';

  @override
  String get userFormLinesFailed => 'The lines could not be loaded.';

  @override
  String get userFormUserNameInvalid =>
      'Only letters, digits, dots, underscores and hyphens are allowed.';

  @override
  String get userFormUserNameTaken => 'This user name is already in use.';

  @override
  String get userFormOutsideScope =>
      'You can only manage users of your own plant.';

  @override
  String get userFormSubmit => 'Create user';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get userDetailTitle => 'User';

  @override
  String get userDetailTemporaryPassword => 'Temporary password';

  @override
  String get userDetailSelfInfo =>
      'This is your own account. You cannot deactivate it or reset its password here.';

  @override
  String get userDetailAccountSection => 'Account status';

  @override
  String get userDetailActiveInfo =>
      'The account is active. Deactivating it blocks sign-in and closes open sessions.';

  @override
  String get userDetailInactiveInfo =>
      'The account is inactive. The user cannot sign in.';

  @override
  String get userDetailDeactivate => 'Deactivate';

  @override
  String get userDetailActivate => 'Activate';

  @override
  String get userDetailDeactivateTitle => 'Deactivate this user?';

  @override
  String userDetailDeactivateMessage(String name) {
    return '$name will no longer be able to sign in, and their sessions on every device will be closed.';
  }

  @override
  String get userDetailPasswordSection => 'Password';

  @override
  String get userDetailPasswordInfo =>
      'If the user forgot their password, give them a new temporary one. Their sessions on every device are closed and they must change it at first sign-in.';

  @override
  String get userDetailResetPassword => 'Give temporary password';

  @override
  String get userDetailResetPasswordTitle => 'New temporary password';

  @override
  String get userDetailResetPasswordSubmit => 'Set password';

  @override
  String get userDetailActivated => 'User activated.';

  @override
  String get userDetailDeactivated => 'User deactivated.';

  @override
  String get userDetailPasswordReset =>
      'Temporary password set. Share it with the user in a safe way.';

  @override
  String get userFormPlantsFailed => 'The plants could not be loaded.';

  @override
  String get userDetailAccessSection => 'Access';

  @override
  String userDetailAccessInfo(String role) {
    return 'Role: $role. Changing the role, plant or line closes the user\'s sessions.';
  }

  @override
  String get userDetailEditAccess => 'Change access';

  @override
  String get userDetailAccessChanged => 'Access updated.';

  @override
  String get editAccessInfo =>
      'Saving closes the user\'s sessions on every device; they must sign in again with their new access.';

  @override
  String get editAccessSave => 'Save';
}
