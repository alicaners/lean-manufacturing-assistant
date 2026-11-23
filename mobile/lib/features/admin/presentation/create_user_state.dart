import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/plant.dart';

/// Loading state of a list of choices (plants, lines).
enum OptionsStatus { idle, loading, ready, failed }

/// Everything the new-user form needs from the server.
class CreateUserState {
  const CreateUserState({
    this.plants = const [],
    this.plantsStatus = OptionsStatus.loading,
    this.lines = const [],
    this.linesStatus = OptionsStatus.idle,
    this.loadFailure,
    this.submit = const SubmitIdle(),
  });

  final List<Plant> plants;
  final OptionsStatus plantsStatus;

  /// Lines of the chosen plant.
  final List<PlantLine> lines;
  final OptionsStatus linesStatus;

  /// Why the plants or lines could not be loaded.
  final Failure? loadFailure;

  final SubmitState submit;

  CreateUserState copyWith({
    List<Plant>? plants,
    OptionsStatus? plantsStatus,
    List<PlantLine>? lines,
    OptionsStatus? linesStatus,
    Failure? loadFailure,
    SubmitState? submit,
  }) {
    return CreateUserState(
      plants: plants ?? this.plants,
      plantsStatus: plantsStatus ?? this.plantsStatus,
      lines: lines ?? this.lines,
      linesStatus: linesStatus ?? this.linesStatus,
      loadFailure: loadFailure ?? this.loadFailure,
      submit: submit ?? this.submit,
    );
  }
}
