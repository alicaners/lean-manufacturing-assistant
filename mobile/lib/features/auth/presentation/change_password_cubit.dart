import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/auth/domain/auth_repository.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';

/// Sends the change-password form. After success it asks [AuthBloc] to reload
/// the user, who no longer must change the password; the router moves on.
@injectable
class ChangePasswordCubit extends Cubit<SubmitState> {
  ChangePasswordCubit(this._repository, this._authBloc)
    : super(const SubmitIdle());

  final AuthRepository _repository;
  final AuthBloc _authBloc;

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state is SubmitInProgress) return;

    emit(const SubmitInProgress());

    final result = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (isClosed) return;

    switch (result) {
      case Ok():
        _authBloc.add(const AuthCheckRequested());
      case Err(:final failure):
        emit(SubmitFailed(failure));
    }
  }
}
