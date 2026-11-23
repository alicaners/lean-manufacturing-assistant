import 'package:lean_assistant/features/auth/domain/current_user.dart';

/// What the user list is narrowed down to. Every part is optional.
class UserFilter {
  const UserFilter({this.search = '', this.role, this.isActive});

  /// Part of the user name or the full name.
  final String search;

  /// Only users of this role; null means every role.
  final UserRole? role;

  /// true: only active users, false: only deactivated users, null: both.
  final bool? isActive;

  UserFilter withSearch(String search) =>
      UserFilter(search: search, role: role, isActive: isActive);

  UserFilter withRole(UserRole? role) =>
      UserFilter(search: search, role: role, isActive: isActive);

  UserFilter withActive(bool? isActive) =>
      UserFilter(search: search, role: role, isActive: isActive);
}
