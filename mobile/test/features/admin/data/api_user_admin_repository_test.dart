import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/api_client.dart';
import 'package:lean_assistant/core/network/cursor_page.dart';
import 'package:lean_assistant/features/admin/data/api_user_admin_repository.dart';
import 'package:lean_assistant/features/admin/domain/managed_user.dart';
import 'package:lean_assistant/features/admin/domain/new_user.dart';
import 'package:lean_assistant/features/admin/domain/user_filter.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';

import '../../../helpers/fake_json_server.dart';
import '../../../helpers/fake_users.dart';

void main() {
  test('sends the filters and reads the page', () async {
    final server = FakeJsonServer(
      200,
      '{"items":[$operatorUserJson],"nextCursor":"next"}',
    );

    final result = await ApiUserAdminRepository(ApiClient(dioFor(server))).list(
      const UserFilter(
        search: '  demo ',
        role: UserRole.operator,
        isActive: true,
      ),
      cursor: 'abc',
    );

    expect(server.requests.single.path, '/api/users');
    expect(server.requests.single.queryParameters, {
      'search': 'demo',
      'role': 'operator',
      'isActive': true,
      'cursor': 'abc',
    });

    final page = (result as Ok<CursorPage<ManagedUser>>).value;
    expect(page.nextCursor, 'next');
    expect(page.items.single.userName, 'demo.operator');
    expect(page.items.single.role, UserRole.operator);
    expect(page.items.single.lineId, isNull);
  });

  test('leaves out the filters that are not set', () async {
    final server = FakeJsonServer(200, '{"items":[],"nextCursor":null}');

    final result = await ApiUserAdminRepository(ApiClient(dioFor(server)))
        .list(const UserFilter());

    expect(server.requests.single.queryParameters, isEmpty);
    expect((result as Ok<CursorPage<ManagedUser>>).value.nextCursor, isNull);
  });

  test('creates a user with a temporary password', () async {
    final server = FakeJsonServer(201, operatorUserJson);

    final result = await ApiUserAdminRepository(ApiClient(dioFor(server)))
        .create(
          const NewUser(
            userName: 'demo.operator',
            fullName: 'Demo Operatör',
            temporaryPassword: 'Temporary-Password-1',
            role: UserRole.operator,
            plantId: 'p-1',
            lineId: 'l-1',
          ),
        );

    expect(server.requests.single.method, 'POST');
    expect(server.requests.single.path, '/api/users');
    expect(server.requests.single.data, {
      'userName': 'demo.operator',
      'fullName': 'Demo Operatör',
      'password': 'Temporary-Password-1',
      'role': 'Operator',
      'factoryId': 'p-1',
      'lineId': 'l-1',
    });
    expect((result as Ok<ManagedUser>).value.userName, 'demo.operator');
  });

  test('reads one user', () async {
    final server = FakeJsonServer(200, operatorUserJson);

    final result = await ApiUserAdminRepository(ApiClient(dioFor(server)))
        .get('u-1');

    expect(server.requests.single.path, '/api/users/u-1');
    expect((result as Ok<ManagedUser>).value.fullName, 'Demo Operatör');
  });

  test('deactivates and activates a user', () async {
    final server = FakeJsonServer(204, '');
    final repository = ApiUserAdminRepository(ApiClient(dioFor(server)));

    final deactivated = await repository.setActive('u-1', active: false);
    final activated = await repository.setActive('u-1', active: true);

    expect(
      [for (final request in server.requests) request.path],
      ['/api/users/u-1/deactivate', '/api/users/u-1/activate'],
    );
    expect(deactivated, isA<Ok<void>>());
    expect(activated, isA<Ok<void>>());
  });

  test('gives a user a new temporary password', () async {
    final server = FakeJsonServer(204, '');

    final result = await ApiUserAdminRepository(ApiClient(dioFor(server)))
        .resetPassword('u-1', 'New-Temporary-Password');

    expect(server.requests.single.path, '/api/users/u-1/reset-password');
    expect(server.requests.single.data, {
      'newPassword': 'New-Temporary-Password',
    });
    expect(result, isA<Ok<void>>());
  });
}
