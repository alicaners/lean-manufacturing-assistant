import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/features/auth/domain/auth_repository.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';

/// The single source of truth for who is signed in.
/// Lives as long as the app; the router redirects whenever it changes.
@lazySingleton
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthUnknown()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthSessionExpired>((_, emit) => emit(const AuthSignedOut()));

    _expiredSubscription = _repository.sessionExpired.listen(
      (_) => add(const AuthSessionExpired()),
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<void> _expiredSubscription;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Coming back from an error: show the progress again while we retry.
    if (state is AuthUnavailable) {
      emit(const AuthUnknown());
    }

    if (await _repository.currentSession() == null) {
      emit(const AuthSignedOut());
      return;
    }

    final result = await _repository.me();

    emit(switch (result) {
      Ok(:final value) => AuthSignedIn(value),
      Err(failure: UnauthorizedFailure()) => const AuthSignedOut(),
      Err(:final failure) => AuthUnavailable(failure),
    });
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.signOut();
    emit(const AuthSignedOut());
  }

  @override
  Future<void> close() async {
    await _expiredSubscription.cancel();
    return super.close();
  }
}
