import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';
import 'package:lean_assistant/features/auth/domain/permission.dart';

void main() {
  test('only admins manage users and the organization', () {
    for (final role in UserRole.values) {
      final isAdmin = role == UserRole.admin;
      expect(role.can(Permission.manageUsers), isAdmin, reason: '$role');
      expect(role.can(Permission.manageOrganization), isAdmin, reason: '$role');
    }
  });

  test('downtime is reported by operators and resolved by technicians', () {
    expect(UserRole.operator.can(Permission.reportDowntime), isTrue);
    expect(UserRole.operator.can(Permission.resolveDowntime), isFalse);
    expect(UserRole.technician.can(Permission.resolveDowntime), isTrue);
    expect(UserRole.technician.can(Permission.reportDowntime), isFalse);
  });
}
