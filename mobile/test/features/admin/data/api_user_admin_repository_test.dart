import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/api_client.dart';
import 'package:lean_assistant/core/network/cursor_page.dart';
import 'package:lean_assistant/features/admin/data/api_user_admin_repository.dart';
import 'package:lean_assistant/features/admin/domain/managed_user.dart';
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
}
