import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';

extension UserRoleLabel on UserRole {
  /// The role's name in the user's language.
  String label(AppLocalizations l10n) => switch (this) {
    UserRole.operator => l10n.roleOperator,
    UserRole.supervisor => l10n.roleSupervisor,
    UserRole.technician => l10n.roleTechnician,
    UserRole.manager => l10n.roleManager,
    UserRole.admin => l10n.roleAdmin,
  };
}
