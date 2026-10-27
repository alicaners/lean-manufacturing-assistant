/// What the app may show and do depends on this. Mirrors the backend's `Role`.
enum UserRole {
  operator,
  supervisor,
  technician,
  manager,
  admin;

  /// The API writes roles as text, e.g. "Supervisor".
  static UserRole parse(Object? value) => switch (value) {
    'Operator' => UserRole.operator,
    'Supervisor' => UserRole.supervisor,
    'Technician' => UserRole.technician,
    'Manager' => UserRole.manager,
    'Admin' => UserRole.admin,
    _ => throw FormatException('Unknown role: $value'),
  };
}

/// The signed-in user, as `GET /api/auth/me` returns it.
class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.role,
    required this.mustChangePassword,
  });

  /// Throws [FormatException] if a field is missing, has the wrong type,
  /// or the role is unknown.
  factory CurrentUser.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'userName': final String userName,
      'fullName': final String fullName,
      'role': final String role,
      'mustChangePassword': final bool mustChangePassword,
    }) {
      return CurrentUser(
        id: id,
        userName: userName,
        fullName: fullName,
        role: UserRole.parse(role),
        mustChangePassword: mustChangePassword,
      );
    }

    throw const FormatException('Unexpected user response.');
  }

  final String id;
  final String userName;
  final String fullName;
  final UserRole role;
  final bool mustChangePassword;
}
