import 'package:lean_assistant/features/auth/domain/current_user.dart';

/// What an admin fills in to create a user.
class NewUser {
  const NewUser({
    required this.userName,
    required this.fullName,
    required this.temporaryPassword,
    required this.role,
    this.plantId,
    this.lineId,
  });

  final String userName;
  final String fullName;

  /// Set by the admin; the user must replace it at first sign-in.
  final String temporaryPassword;

  final UserRole role;

  /// Null only for a system-wide admin.
  final String? plantId;

  /// Only for roles that work on a line.
  final String? lineId;
}
