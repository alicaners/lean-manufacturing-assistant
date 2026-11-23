import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/plant.dart';
import 'package:lean_assistant/features/admin/domain/plant_tree.dart';

enum OrganizationStatus { loading, ready, failed }

class OrganizationState {
  const OrganizationState({
    this.status = OrganizationStatus.loading,
    this.plants = const [],
    this.plantId,
    this.tree,
    this.failure,
    this.change = const SubmitIdle(),
  });

  final OrganizationStatus status;

  /// The plants the admin may manage; a system admin may have several.
  final List<Plant> plants;

  /// The plant whose tree is shown.
  final String? plantId;

  final PlantTree? tree;

  /// Why the plants or the tree could not be loaded.
  final Failure? failure;

  /// The last add or rename.
  final SubmitState change;

  OrganizationState copyWith({
    OrganizationStatus? status,
    List<Plant>? plants,
    String? plantId,
    PlantTree? tree,
    Failure? failure,
    SubmitState? change,
  }) {
    return OrganizationState(
      status: status ?? this.status,
      plants: plants ?? this.plants,
      plantId: plantId ?? this.plantId,
      tree: tree ?? this.tree,
      failure: failure ?? this.failure,
      change: change ?? this.change,
    );
  }
}
