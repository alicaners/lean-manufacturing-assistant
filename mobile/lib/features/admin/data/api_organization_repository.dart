import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/api_client.dart';
import 'package:lean_assistant/features/admin/domain/organization_repository.dart';
import 'package:lean_assistant/features/admin/domain/plant.dart';
import 'package:lean_assistant/features/admin/domain/plant_tree.dart';

/// [OrganizationRepository] backed by the organization endpoints.
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

  @override
  Future<Result<PlantTree>> tree(String plantId) {
    return _api.get('/api/factories/$plantId/tree', parse: PlantTree.fromJson);
  }

  @override
  Future<Result<void>> addDepartment(String plantId, String name) {
    return _api.post(
      '/api/factories/$plantId/departments',
      body: {'name': name},
      parse: _ignore,
    );
  }

  @override
  Future<Result<void>> addLine(String departmentId, String name) {
    return _api.post(
      '/api/departments/$departmentId/lines',
      body: {'name': name},
      parse: _ignore,
    );
  }

  @override
  Future<Result<void>> addMachine(
    String lineId, {
    required String name,
    required String code,
  }) {
    return _api.post(
      '/api/lines/$lineId/machines',
      body: {'name': name, 'code': code},
      parse: _ignore,
    );
  }

  @override
  Future<Result<void>> rename(TreeNodeKind kind, String id, String name) {
    final collection = switch (kind) {
      TreeNodeKind.department => 'departments',
      TreeNodeKind.line => 'lines',
      TreeNodeKind.machine => 'machines',
    };
    return _api.put(
      '/api/$collection/$id',
      body: {'name': name},
      parse: _ignore,
    );
  }

  static List<Plant> _plantList(Object? json) {
    if (json is List<Object?>) {
      return [for (final item in json) Plant.fromJson(item)];
    }
    throw const FormatException('Unexpected plant list.');
  }

  /// The tree is read again after every change; this answer is not needed.
  static void _ignore(Object? _) {}
}
