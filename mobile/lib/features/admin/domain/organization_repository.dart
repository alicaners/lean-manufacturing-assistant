import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/features/admin/domain/machine_detail.dart';
import 'package:lean_assistant/features/admin/domain/plant.dart';
import 'package:lean_assistant/features/admin/domain/plant_tree.dart';

/// Plants, their departments, lines and machines.
abstract interface class OrganizationRepository {
  /// The plants the signed-in user may see: every plant for a system-wide
  /// admin, otherwise only their own.
  Future<Result<List<Plant>>> plants();

  /// Every line of the plant.
  Future<Result<List<PlantLine>>> lines(String plantId);

  /// The whole plant: departments, lines and machines.
  Future<Result<PlantTree>> tree(String plantId);

  Future<Result<void>> addDepartment(String plantId, String name);

  Future<Result<void>> addLine(String departmentId, String name);

  Future<Result<void>> addMachine(
    String lineId, {
    required String name,
    required String code,
  });

  Future<Result<void>> rename(TreeNodeKind kind, String id, String name);

  /// One machine with its QR code.
  Future<Result<MachineDetail>> machine(String id);

  /// Replaces the machine's QR code; the old label stops working.
  Future<Result<MachineDetail>> regenerateQr(String id);
}
