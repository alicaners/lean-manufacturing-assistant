import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/api_client.dart';
import 'package:lean_assistant/features/dashboard/domain/health_repository.dart';
import 'package:lean_assistant/features/dashboard/domain/server_health.dart';

/// [HealthRepository] backed by the API's `/health` endpoint.
@LazySingleton(as: HealthRepository)
class ApiHealthRepository implements HealthRepository {
  ApiHealthRepository(this._api);

  final ApiClient _api;

  @override
  Future<Result<ServerHealth>> check() {
    return _api.get('/health', parse: ServerHealth.parse);
  }
}
