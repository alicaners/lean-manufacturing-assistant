import 'package:lean_assistant/features/auth/domain/current_user.dart';

/// A user as an admin sees it in user management (`/api/users`).
class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.mustChangePassword,
    this.factoryId,
    this.lineId,
  });

  /// Throws [FormatException] if a field is missing, has the wrong type,
  /// or the role is unknown.
  factory ManagedUser.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'userName': final String userName,
      'fullName': final String fullName,
      'role': final String role,
      'isActive': final bool isActive,
      'mustChangePassword': final bool mustChangePassword,
      'factoryId': final String? factoryId,
      'lineId': final String? lineId,
    }) {
      return ManagedUser(
        id: id,
        userName: userName,
        fullName: fullName,
        role: UserRole.parse(role),
        isActive: isActive,
        mustChangePassword: mustChangePassword,
        factoryId: factoryId,
        lineId: lineId,
      );
    }

    throw const FormatException('Unexpected user response.');
  }

  final String id;
  final String userName;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final bool mustChangePassword;

  /// The plant the user belongs to; null for a system-wide admin.
  final String? factoryId;

  /// The line the user works on; only operators and supervisors have one.
  final String? lineId;
}
