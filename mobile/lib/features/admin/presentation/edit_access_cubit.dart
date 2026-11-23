import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/user_access.dart';
import 'package:lean_assistant/features/admin/domain/user_admin_repository.dart';

/// Saves a user's new role, plant and line.
@injectable
class EditAccessCubit extends Cubit<SubmitState> {
  EditAccessCubit(this._users) : super(const SubmitIdle());

  final UserAdminRepository _users;

  Future<void> save(String userId, UserAccess access) async {
    if (state is SubmitInProgress) return;

    emit(const SubmitInProgress());

    final result = await _users.updateAccess(userId, access);
    if (isClosed) return;

    emit(switch (result) {
      Ok() => const SubmitSucceeded(),
      Err(:final failure) => SubmitFailed(failure),
    });
  }
}
