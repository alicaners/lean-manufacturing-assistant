import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/auth/domain/auth_repository.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';

/// Sends the sign-in form. After success it asks [AuthBloc] to load the user;
/// the router then leaves the sign-in page by itself.
@injectable
class LoginCubit extends Cubit<SubmitState> {
  LoginCubit(this._repository, this._authBloc) : super(const SubmitIdle());

  final AuthRepository _repository;
  final AuthBloc _authBloc;

  Future<void> submit({
    required String userName,
    required String password,
  }) async {
    // A second tap while waiting must not send a second request.
    if (state is SubmitInProgress) return;

    emit(const SubmitInProgress());

    final result = await _repository.signIn(
      userName: userName.trim(),
      password: password,
    );

    if (isClosed) return;

    switch (result) {
      case Ok():
        // Stays "in progress": the router leaves this page once the user is loaded.
        _authBloc.add(const AuthCheckRequested());
      case Err(:final failure):
        emit(SubmitFailed(failure));
    }
  }
}
