import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/managed_user.dart';
import 'package:lean_assistant/features/admin/domain/user_admin_repository.dart';
import 'package:lean_assistant/features/admin/presentation/user_detail_state.dart';

/// Loads one user and runs the admin's actions on them.
@injectable
class UserDetailCubit extends Cubit<UserDetailState> {
  UserDetailCubit(this._users) : super(const UserDetailState());

  final UserAdminRepository _users;

  Future<void> load(String id) async {
    // The first load starts in "loading" already; a retry goes back to it.
    if (state.status != UserDetailStatus.loading) {
      emit(const UserDetailState());
    }

    final result = await _users.get(id);
    if (isClosed) return;

    emit(switch (result) {
      Ok(:final value) => UserDetailState(
        status: UserDetailStatus.ready,
        user: value,
      ),
      Err(:final failure) => UserDetailState(
        status: UserDetailStatus.failed,
        loadFailure: failure,
      ),
    });
  }

  Future<void> setActive({required bool active}) => _run(
    active ? UserAction.activate : UserAction.deactivate,
    (user) => _users.setActive(user.id, active: active),
  );

  Future<void> resetPassword(String temporaryPassword) => _run(
    UserAction.resetPassword,
    (user) => _users.resetPassword(user.id, temporaryPassword),
  );

  /// Runs [action], then reads the user again so the page shows what the
  /// server now holds (e.g. "inactive" or "temporary password").
  Future<void> _run(
    UserAction action,
    Future<Result<void>> Function(ManagedUser user) send,
  ) async {
    final user = state.user;
    if (user == null || state.action is SubmitInProgress) return;

    emit(_withAction(const SubmitInProgress(), action));

    final result = await send(user);
    if (isClosed) return;

    if (result case Err(:final failure)) {
      emit(_withAction(SubmitFailed(failure), action));
      return;
    }

    final reloaded = await _users.get(user.id);
    if (isClosed) return;

    emit(
      UserDetailState(
        status: UserDetailStatus.ready,
        // The action worked; if reading back fails, keep what we have.
        user: switch (reloaded) {
          Ok(:final value) => value,
          Err() => user,
        },
        action: const SubmitSucceeded(),
        lastAction: action,
      ),
    );
  }

  UserDetailState _withAction(SubmitState submit, UserAction action) {
    return UserDetailState(
      status: state.status,
      user: state.user,
      action: submit,
      lastAction: action,
    );
  }
}
