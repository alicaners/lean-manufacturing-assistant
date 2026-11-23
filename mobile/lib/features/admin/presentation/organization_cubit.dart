import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/organization_repository.dart';
import 'package:lean_assistant/features/admin/domain/plant_tree.dart';
import 'package:lean_assistant/features/admin/presentation/organization_state.dart';

/// Shows a plant's tree and applies the admin's changes to it.
@injectable
class OrganizationCubit extends Cubit<OrganizationState> {
  OrganizationCubit(this._organization) : super(const OrganizationState());

  final OrganizationRepository _organization;

  /// Loads the plants, then the tree of the chosen (or first) plant.
  Future<void> load() async {
    if (state.status != OrganizationStatus.loading) {
      emit(state.copyWith(status: OrganizationStatus.loading));
    }

    final result = await _organization.plants();
    if (isClosed) return;

    switch (result) {
      case Err(:final failure):
        emit(
          state.copyWith(status: OrganizationStatus.failed, failure: failure),
        );
      case Ok(value: final plants) when plants.isEmpty:
        emit(
          state.copyWith(status: OrganizationStatus.ready, plants: const []),
        );
      case Ok(value: final plants):
        final plantId = state.plantId ?? plants.first.id;
        emit(state.copyWith(plants: plants, plantId: plantId));
        await _loadTree(plantId);
    }
  }

  Future<void> selectPlant(String plantId) async {
    if (plantId == state.plantId) return;

    emit(state.copyWith(status: OrganizationStatus.loading, plantId: plantId));
    await _loadTree(plantId);
  }

  Future<void> addDepartment(String name) =>
      _change((plantId) => _organization.addDepartment(plantId, name));

  Future<void> addLine(String departmentId, String name) =>
      _change((_) => _organization.addLine(departmentId, name));

  Future<void> addMachine(
    String lineId, {
    required String name,
    required String code,
  }) =>
      _change((_) => _organization.addMachine(lineId, name: name, code: code));

  Future<void> rename(TreeNodeKind kind, String id, String name) =>
      _change((_) => _organization.rename(kind, id, name));

  Future<void> _loadTree(String plantId) async {
    final result = await _organization.tree(plantId);

    // Another plant was chosen meanwhile.
    if (isClosed || plantId != state.plantId) return;

    emit(switch (result) {
      Ok(:final value) => state.copyWith(
        status: OrganizationStatus.ready,
        tree: value,
      ),
      Err(:final failure) => state.copyWith(
        status: OrganizationStatus.failed,
        failure: failure,
      ),
    });
  }

  /// Sends one change, then reads the tree again so the page shows exactly
  /// what the server now holds.
  Future<void> _change(
    Future<Result<void>> Function(String plantId) send,
  ) async {
    final plantId = state.plantId;
    if (plantId == null || state.change is SubmitInProgress) return;

    emit(state.copyWith(change: const SubmitInProgress()));

    final result = await send(plantId);
    if (isClosed) return;

    if (result case Err(:final failure)) {
      emit(state.copyWith(change: SubmitFailed(failure)));
      return;
    }

    final tree = await _organization.tree(plantId);
    if (isClosed) return;

    emit(
      state.copyWith(
        // The change worked; if reading back fails, keep the old tree.
        tree: switch (tree) {
          Ok(:final value) => value,
          Err() => null,
        },
        change: const SubmitSucceeded(),
      ),
    );
  }
}
