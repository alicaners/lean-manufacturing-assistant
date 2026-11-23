import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/managed_user.dart';
import 'package:lean_assistant/features/admin/domain/user_admin_repository.dart';
import 'package:lean_assistant/features/admin/presentation/user_detail_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/user_detail_state.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_users.dart';

class _MockUsers extends Mock implements UserAdminRepository {}

/// [operatorUser] after it was deactivated.
const _deactivatedOperator = ManagedUser(
  id: '01a177de-2504-7c0a-a458-d380e5314f01',
  userName: 'demo.operator',
  fullName: 'Demo Operatör',
  role: UserRole.operator,
  isActive: false,
  mustChangePassword: false,
);

const _loaded = UserDetailState(
  status: UserDetailStatus.ready,
  user: operatorUser,
);

void main() {
  late _MockUsers users;

  setUp(() => users = _MockUsers());

  blocTest<UserDetailCubit, UserDetailState>(
    'loads the user',
    setUp: () =>
        when(() => users.get(operatorUser.id))
            .thenAnswer((_) async => const Ok(operatorUser)),
    build: () => UserDetailCubit(users),
    act: (cubit) => cubit.load(operatorUser.id),
    expect: () => [
      isA<UserDetailState>()
          .having((state) => state.status, 'status', UserDetailStatus.ready)
          .having((state) => state.user, 'user', operatorUser),
    ],
  );

  blocTest<UserDetailCubit, UserDetailState>(
    'deactivates the user and shows what the server now holds',
    setUp: () {
      when(() => users.setActive(operatorUser.id, active: false))
          .thenAnswer((_) async => const Ok<void>(null));
      when(() => users.get(operatorUser.id))
          .thenAnswer((_) async => const Ok(_deactivatedOperator));
    },
    build: () => UserDetailCubit(users),
    seed: () => _loaded,
    act: (cubit) => cubit.setActive(active: false),
    expect: () => [
      isA<UserDetailState>()
          .having((state) => state.action, 'action', isA<SubmitInProgress>())
          .having(
            (state) => state.lastAction,
            'lastAction',
            UserAction.deactivate,
          ),
      isA<UserDetailState>()
          .having((state) => state.action, 'action', isA<SubmitSucceeded>())
          .having((state) => state.user?.isActive, 'isActive', isFalse),
    ],
  );

  blocTest<UserDetailCubit, UserDetailState>(
    'keeps the user as it was when the server refuses',
    setUp: () =>
        when(() => users.resetPassword(operatorUser.id, any()))
            .thenAnswer((_) async => const Err(ForbiddenFailure())),
    build: () => UserDetailCubit(users),
    seed: () => _loaded,
    act: (cubit) => cubit.resetPassword('New-Temporary-Password'),
    expect: () => [
      isA<UserDetailState>().having(
        (state) => state.action,
        'action',
        isA<SubmitInProgress>(),
      ),
      isA<UserDetailState>()
          .having((state) => state.action, 'action', isA<SubmitFailed>())
          .having((state) => state.user, 'user', operatorUser),
    ],
    verify: (_) => verifyNever(() => users.get(any())),
  );
}
