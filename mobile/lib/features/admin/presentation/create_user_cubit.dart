import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/new_user.dart';
import 'package:lean_assistant/features/admin/domain/organization_repository.dart';
import 'package:lean_assistant/features/admin/domain/user_admin_repository.dart';
import 'package:lean_assistant/features/admin/presentation/create_user_state.dart';

/// Loads the choices for the new-user form and creates the user.
@injectable
class CreateUserCubit extends Cubit<CreateUserState> {
  CreateUserCubit(this._users, this._organization)
    : super(const CreateUserState());

  final UserAdminRepository _users;
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
        loadFailure: failure,
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
        loadFailure: failure,
      ),
    });
  }

  Future<void> submit(NewUser user) async {
    if (state.submit is SubmitInProgress) return;

    emit(state.copyWith(submit: const SubmitInProgress()));

    final result = await _users.create(user);
    if (isClosed) return;

    emit(
      state.copyWith(
        submit: switch (result) {
          Ok() => const SubmitSucceeded(),
          Err(:final failure) => SubmitFailed(failure),
        },
      ),
    );
  }
}
