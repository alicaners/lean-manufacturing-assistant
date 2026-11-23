import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/new_user.dart';
import 'package:lean_assistant/features/admin/domain/user_admin_repository.dart';
import 'package:lean_assistant/features/admin/presentation/create_user_cubit.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_users.dart';

class _MockUsers extends Mock implements UserAdminRepository {}

const _newUser = NewUser(
  userName: 'new.operator',
  fullName: 'Yeni Operatör',
  temporaryPassword: 'Temporary-Password-1',
  role: UserRole.operator,
  plantId: 'p-1',
  lineId: 'l-1',
);

void main() {
  late _MockUsers users;

  setUpAll(() => registerFallbackValue(_newUser));

  setUp(() => users = _MockUsers());

  blocTest<CreateUserCubit, SubmitState>(
    'reports success once the user is created',
    setUp: () => when(
      () => users.create(any()),
    ).thenAnswer((_) async => const Ok(operatorUser)),
    build: () => CreateUserCubit(users),
    act: (cubit) => cubit.submit(_newUser),
    expect: () => [isA<SubmitInProgress>(), isA<SubmitSucceeded>()],
    verify: (_) => verify(() => users.create(_newUser)).called(1),
  );

  blocTest<CreateUserCubit, SubmitState>(
    'shows why the user could not be created',
    setUp: () => when(
      () => users.create(any()),
    ).thenAnswer((_) async => const Err(ConflictFailure())),
    build: () => CreateUserCubit(users),
    act: (cubit) => cubit.submit(_newUser),
    expect: () => [
      isA<SubmitInProgress>(),
      isA<SubmitFailed>().having(
        (submit) => submit.failure,
        'failure',
        isA<ConflictFailure>(),
      ),
    ],
  );
}