import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/auth/domain/auth_repository.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';
import 'package:lean_assistant/features/auth/presentation/change_password_cubit.dart';
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

  blocTest<ChangePasswordCubit, SubmitState>(
    'reloads the user after the password is changed',
    setUp: () => when(
      () => repository.changePassword(
        currentPassword: any(named: 'currentPassword'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async => Ok(validSession())),
    build: () => ChangePasswordCubit(repository, authBloc),
    act: (cubit) => cubit.submit(
      currentPassword: 'Temporary-Password-1',
      newPassword: 'My-Own-Password-2',
    ),
    expect: () => [isA<SubmitInProgress>()],
    verify: (_) =>
        verify(() => authBloc.add(const AuthCheckRequested())).called(1),
  );

  blocTest<ChangePasswordCubit, SubmitState>(
    'shows the failure when the server refuses the change',
    setUp: () =>
        when(
          () => repository.changePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          ),
        ).thenAnswer(
          (_) async => const Err(
            ValidationFailure(
              fieldErrors: {
                'CurrentPassword': ['The current password is not correct.'],
              },
            ),
          ),
        ),
    build: () => ChangePasswordCubit(repository, authBloc),
    act: (cubit) => cubit.submit(
      currentPassword: 'wrong',
      newPassword: 'My-Own-Password-2',
    ),
    expect: () => [isA<SubmitInProgress>(), isA<SubmitFailed>()],
    verify: (_) => verifyNever(() => authBloc.add(const AuthCheckRequested())),
  );
}
