import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';

Map<String, Object?> _profile({String role = 'Operator'}) => {
  'id': '01a177de-2504-7c0a-a458-d380e5314fba',
  'userName': 'demo.operator',
  'fullName': 'Demo Operatör',
  'role': role,
  'mustChangePassword': false,
};

void main() {
  test('reads the profile and maps the role', () {
    final user = CurrentUser.fromJson(_profile(role: 'Supervisor'));

    expect(user.userName, 'demo.operator');
    expect(user.fullName, 'Demo Operatör');
    expect(user.role, UserRole.supervisor);
    expect(user.mustChangePassword, isFalse);
  });

  test('rejects an unknown role', () {
    expect(
      () => CurrentUser.fromJson(_profile(role: 'Janitor')),
      throwsFormatException,
    );
  });
}
