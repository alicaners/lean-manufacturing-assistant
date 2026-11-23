import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/features/admin/domain/plant.dart';

/// Loading state of a list of choices.
enum OptionsStatus { idle, loading, ready, failed }

/// The plants and lines a role/plant/line form can offer.
class AccessOptionsState {
  const AccessOptionsState({
    this.plants = const [],
    this.plantsStatus = OptionsStatus.loading,
    this.lines = const [],
    this.linesStatus = OptionsStatus.idle,
    this.failure,
  });

  final List<Plant> plants;
  final OptionsStatus plantsStatus;

  /// Lines of the chosen plant.
  final List<PlantLine> lines;
  final OptionsStatus linesStatus;

  /// Why the plants or lines could not be loaded.
  final Failure? failure;

  AccessOptionsState copyWith({
    List<Plant>? plants,
    OptionsStatus? plantsStatus,
    List<PlantLine>? lines,
    OptionsStatus? linesStatus,
    Failure? failure,
  }) {
    return AccessOptionsState(
      plants: plants ?? this.plants,
      plantsStatus: plantsStatus ?? this.plantsStatus,
      lines: lines ?? this.lines,
      linesStatus: linesStatus ?? this.linesStatus,
      failure: failure ?? this.failure,
    );
  }
}
