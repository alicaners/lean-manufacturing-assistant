import 'package:lean_assistant/features/auth/domain/current_user.dart';

/// What a user may do and where: their role, plant and line.
class UserAccess {
  const UserAccess({required this.role, this.plantId, this.lineId});

  final UserRole role;

  /// Null only for a system-wide admin.
  final String? plantId;

  /// Only for roles that work on a line.
  final String? lineId;

  /// Keeps the plant; drops the line if the new role has none.
  UserAccess withRole(UserRole role) => UserAccess(
    role: role,
    plantId: plantId,
    lineId: role.worksOnLine ? lineId : null,
  );

  /// Another plant has other lines, so the line is cleared.
  UserAccess withPlant(String? plantId) =>
      UserAccess(role: role, plantId: plantId);

  UserAccess withLine(String? lineId) =>
      UserAccess(role: role, plantId: plantId, lineId: lineId);
}

/// Which plant and line a role needs (docs/business-rules.md).
extension UserRoleScope on UserRole {
  /// Every role except Admin sees only its own plant, so it must have one.
  bool get needsPlant => this != UserRole.admin;

  /// Operators and supervisors act on "their own line".
  bool get worksOnLine =>
      this == UserRole.operator || this == UserRole.supervisor;
}
