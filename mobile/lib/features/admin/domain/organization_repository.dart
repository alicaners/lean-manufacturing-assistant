import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/features/admin/domain/plant.dart';

/// Plants and lines, for choosing where a user works.
abstract interface class OrganizationRepository {
  /// The plants the signed-in user may see: every plant for a system-wide
  /// admin, otherwise only their own.
  Future<Result<List<Plant>>> plants();

  /// Every line of the plant.
  Future<Result<List<PlantLine>>> lines(String plantId);
}
