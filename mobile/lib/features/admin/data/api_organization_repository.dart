import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/api_client.dart';
import 'package:lean_assistant/features/admin/domain/organization_repository.dart';
import 'package:lean_assistant/features/admin/domain/plant.dart';

/// [OrganizationRepository] backed by `/api/factories`.
@LazySingleton(as: OrganizationRepository)
class ApiOrganizationRepository implements OrganizationRepository {
  ApiOrganizationRepository(this._api);

  final ApiClient _api;

  @override
  Future<Result<List<Plant>>> plants() {
    return _api.get('/api/factories', parse: _plantList);
  }

  @override
  Future<Result<List<PlantLine>>> lines(String plantId) {
    return _api.get(
      '/api/factories/$plantId/tree',
      parse: PlantLine.listFromTree,
    );
  }

  static List<Plant> _plantList(Object? json) {
    if (json is List<Object?>) {
      return [for (final item in json) Plant.fromJson(item)];
    }
    throw const FormatException('Unexpected plant list.');
  }
}
