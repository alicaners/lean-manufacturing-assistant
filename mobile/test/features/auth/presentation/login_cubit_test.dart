import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/auth/domain/auth_repository.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';
import 'package:lean_assistant/features/auth/presentation/login_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_auth.dart';
import '../../../helpers/fake_auth_server.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late MockAuthBloc authBloc;

  setUp(() {
    repository = _MockAuthRepository();
    authBloc = MockAuthBloc();
  });

  void givenSignInAnswers(Result<Never> Function()? failure) {
    when(
      () => repository.signIn(
        userName: any(named: 'userName'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => failure?.call() ?? Ok(validSession()));
  }

  blocTest<LoginCubit, SubmitState>(
    'loads the user after a successful sign-in',
    setUp: () => givenSignInAnswers(null),
    build: () => LoginCubit(repository, authBloc),
    act: (cubit) =>
        cubit.submit(userName: ' demo.operator ', password: 'Demo-Password-1'),
    expect: () => [isA<SubmitInProgress>()],
    verify: (_) {
      verify(
        () => repository.signIn(
          userName: 'demo.operator',
          password: 'Demo-Password-1',
        ),
      ).called(1);
      verify(() => authBloc.add(const AuthCheckRequested())).called(1);
    },
  );

  blocTest<LoginCubit, SubmitState>(
    'shows the failure when the password is wrong',
    setUp: () => givenSignInAnswers(() => const Err(UnauthorizedFailure())),
    build: () => LoginCubit(repository, authBloc),
    act: (cubit) => cubit.submit(userName: 'demo.operator', password: 'wrong'),
    expect: () => [
      isA<SubmitInProgress>(),
      isA<SubmitFailed>().having(
        (state) => state.failure,
        'failure',
        isA<UnauthorizedFailure>(),
      ),
    ],
    verify: (_) => verifyNever(() => authBloc.add(const AuthCheckRequested())),
  );

  blocTest<LoginCubit, SubmitState>(
    'ignores another tap while signing in',
    build: () => LoginCubit(repository, authBloc),
    seed: () => const SubmitInProgress(),
    act: (cubit) => cubit.submit(userName: 'demo.operator', password: 'x'),
    expect: () => <SubmitState>[],
    verify: (_) => verifyNever(
      () => repository.signIn(
        userName: any(named: 'userName'),
        password: any(named: 'password'),
      ),
    ),
  );
}
