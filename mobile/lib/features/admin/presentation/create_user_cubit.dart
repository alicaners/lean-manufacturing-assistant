import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/new_user.dart';
import 'package:lean_assistant/features/admin/domain/user_admin_repository.dart';

/// Creates a user. The plant and line choices come from [AccessOptionsCubit].
@injectable
class CreateUserCubit extends Cubit<SubmitState> {
  CreateUserCubit(this._users) : super(const SubmitIdle());

  final UserAdminRepository _users;

  Future<void> submit(NewUser user) async {
    if (state is SubmitInProgress) return;

    emit(const SubmitInProgress());

    final result = await _users.create(user);
    if (isClosed) return;

    emit(switch (result) {
      Ok() => const SubmitSucceeded(),
      Err(:final failure) => SubmitFailed(failure),
    });
  }
}
