import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/features/auth/domain/auth_repository.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_auth.dart';
import '../../../helpers/fake_auth_server.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late StreamController<void> expired;

  setUp(() {
    repository = _MockAuthRepository();
    expired = StreamController<void>.broadcast();
    when(() => repository.sessionExpired).thenAnswer((_) => expired.stream);
  });

  tearDown(() => expired.close());

  void givenStoredSession() {
    when(() => repository.currentSession())
        .thenAnswer((_) async => validSession());
  }

  blocTest<AuthBloc, AuthState>(
    'is signed out when no session is stored',
    setUp: () =>
        when(() => repository.currentSession()).thenAnswer((_) async => null),
    build: () => AuthBloc(repository),
    act: (bloc) => bloc.add(const AuthCheckRequested()),
    expect: () => [isA<AuthSignedOut>()],
    verify: (_) => verifyNever(() => repository.me()),
  );

  blocTest<AuthBloc, AuthState>(
    'is signed in with the profile of the stored session',
    setUp: () {
      givenStoredSession();
      when(() => repository.me()).thenAnswer((_) async => const Ok(testUser));
    },
    build: () => AuthBloc(repository),
    act: (bloc) => bloc.add(const AuthCheckRequested()),
    expect: () => [
      isA<AuthSignedIn>().having(
        (state) => state.user.userName,
        'userName',
        'demo.operator',
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'is signed out when the server no longer accepts the session',
    setUp: () {
      givenStoredSession();
      when(() => repository.me())
          .thenAnswer((_) async => const Err(UnauthorizedFailure()));
    },
    build: () => AuthBloc(repository),
    act: (bloc) => bloc.add(const AuthCheckRequested()),
    expect: () => [isA<AuthSignedOut>()],
  );

  blocTest<AuthBloc, AuthState>(
    'is unavailable when the server cannot be reached',
    setUp: () {
      givenStoredSession();
      when(() => repository.me())
          .thenAnswer((_) async => const Err(NetworkFailure()));
    },
    build: () => AuthBloc(repository),
    act: (bloc) => bloc.add(const AuthCheckRequested()),
    expect: () => [
      isA<AuthUnavailable>().having(
        (state) => state.failure,
        'failure',
        isA<NetworkFailure>(),
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'shows progress again when retrying after an error',
    setUp: () {
      givenStoredSession();
      when(() => repository.me()).thenAnswer((_) async => const Ok(testUser));
    },
    build: () => AuthBloc(repository),
    seed: () => const AuthUnavailable(NetworkFailure()),
    act: (bloc) => bloc.add(const AuthCheckRequested()),
    expect: () => [isA<AuthUnknown>(), isA<AuthSignedIn>()],
  );

  blocTest<AuthBloc, AuthState>(
    'signing out forgets the session',
    setUp: () => when(() => repository.signOut()).thenAnswer((_) async {}),
    build: () => AuthBloc(repository),
    seed: () => const AuthSignedIn(testUser),
    act: (bloc) => bloc.add(const AuthSignOutRequested()),
    expect: () => [isA<AuthSignedOut>()],
    verify: (_) => verify(() => repository.signOut()).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'an expired session signs the user out',
    build: () => AuthBloc(repository),
    seed: () => const AuthSignedIn(testUser),
    act: (_) => expired.add(null),
    expect: () => [isA<AuthSignedOut>()],
  );
}
