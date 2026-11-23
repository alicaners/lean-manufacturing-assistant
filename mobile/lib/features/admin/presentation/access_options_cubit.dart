import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/features/admin/domain/organization_repository.dart';
import 'package:lean_assistant/features/admin/presentation/access_options_state.dart';

/// Loads the plants, and the lines of the chosen plant, for [AccessFields].
@injectable
class AccessOptionsCubit extends Cubit<AccessOptionsState> {
  AccessOptionsCubit(this._organization) : super(const AccessOptionsState());

  final OrganizationRepository _organization;

  /// Grows with every line request; only the newest answer is used.
  int _linesRequest = 0;

  Future<void> loadPlants() async {
    emit(state.copyWith(plantsStatus: OptionsStatus.loading));

    final result = await _organization.plants();
    if (isClosed) return;

    emit(switch (result) {
      Ok(:final value) => state.copyWith(
        plants: value,
        plantsStatus: OptionsStatus.ready,
      ),
      Err(:final failure) => state.copyWith(
        plantsStatus: OptionsStatus.failed,
        failure: failure,
      ),
    });
  }

  /// Loads the lines of the chosen plant; null clears them.
  Future<void> plantChanged(String? plantId) async {
    final request = ++_linesRequest;

    if (plantId == null) {
      emit(state.copyWith(lines: const [], linesStatus: OptionsStatus.idle));
      return;
    }

    emit(state.copyWith(lines: const [], linesStatus: OptionsStatus.loading));

    final result = await _organization.lines(plantId);

    // Another plant was chosen meanwhile; its lines are on their way.
    if (isClosed || request != _linesRequest) return;

    emit(switch (result) {
      Ok(:final value) => state.copyWith(
        lines: value,
        linesStatus: OptionsStatus.ready,
      ),
      Err(:final failure) => state.copyWith(
        linesStatus: OptionsStatus.failed,
        failure: failure,
      ),
    });
  }
}
