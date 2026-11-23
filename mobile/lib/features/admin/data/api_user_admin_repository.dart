import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/api_client.dart';
import 'package:lean_assistant/core/network/cursor_page.dart';
import 'package:lean_assistant/features/admin/domain/managed_user.dart';
import 'package:lean_assistant/features/admin/domain/new_user.dart';
import 'package:lean_assistant/features/admin/domain/user_admin_repository.dart';
import 'package:lean_assistant/features/admin/domain/user_filter.dart';

/// [UserAdminRepository] backed by `/api/users`.
@LazySingleton(as: UserAdminRepository)
class ApiUserAdminRepository implements UserAdminRepository {
  ApiUserAdminRepository(this._api);

  final ApiClient _api;

  @override
  Future<Result<CursorPage<ManagedUser>>> list(
    UserFilter filter, {
    String? cursor,
  }) {
    final search = filter.search.trim();

    return _api.get(
      '/api/users',
      // Only the filters that are set; the API treats a missing one as "any".
      query: {
        if (search.isNotEmpty) 'search': search,
        // The API reads role names in any case ("operator" or "Operator").
        'role': ?filter.role?.name,
        'isActive': ?filter.isActive,
        'cursor': ?cursor,
      },
      parse: (json) =>
          CursorPage<ManagedUser>.fromJson(json, ManagedUser.fromJson),
    );
  }

  @override
  Future<Result<ManagedUser>> create(NewUser user) {
    return _api.post(
      '/api/users',
      body: {
        'userName': user.userName,
        'fullName': user.fullName,
        'password': user.temporaryPassword,
        'role': user.role.apiName,
        // The backend calls a plant "factory".
        'factoryId': user.plantId,
        'lineId': user.lineId,
      },
      parse: ManagedUser.fromJson,
    );
  }
}
