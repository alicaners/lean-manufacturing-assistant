import 'package:lean_assistant/features/auth/domain/current_user.dart';

/// Things a user may be allowed to do, and which roles may do them.
/// Mirrors the backend's `Permission` and `RolePermissions` (and the matrix in
/// docs/business-rules.md). The app uses it only to decide what to show;
/// the server still checks every request.
enum Permission {
  manageUsers({UserRole.admin}),
  manageOrganization({UserRole.admin}),
  reportDowntime({UserRole.operator, UserRole.supervisor}),
  resolveDowntime({UserRole.technician}),
  createSuggestion({
    UserRole.operator,
    UserRole.supervisor,
    UserRole.technician,
  }),
  reviewSuggestion({UserRole.supervisor}),
  performAudit({UserRole.supervisor}),
  viewDashboard({UserRole.manager, UserRole.supervisor});

  const Permission(this.roles);

  /// The roles that hold this permission.
  final Set<UserRole> roles;
}

extension UserRolePermissions on UserRole {
  /// Whether this role holds [permission].
  bool can(Permission permission) => permission.roles.contains(this);
}
