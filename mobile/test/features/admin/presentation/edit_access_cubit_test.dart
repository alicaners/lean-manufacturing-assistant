import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/user_access.dart';
import 'package:lean_assistant/features/admin/domain/user_admin_repository.dart';
import 'package:lean_assistant/features/admin/presentation/edit_access_cubit.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_users.dart';

class _MockUsers extends Mock implements UserAdminRepository {}

const _supervisorAccess = UserAccess(
  role: UserRole.supervisor,
  plantId: 'p-1',
  lineId: 'l-1',
);

void main() {
  late _MockUsers users;

  setUpAll(() => registerFallbackValue(_supervisorAccess));

  setUp(() => users = _MockUsers());

  blocTest<EditAccessCubit, SubmitState>(
    'saves the new access',
    setUp: () =>
        when(() => users.updateAccess('u-1', any()))
            .thenAnswer((_) async => const Ok(operatorUser)),
    build: () => EditAccessCubit(users),
    act: (cubit) => cubit.save('u-1', _supervisorAccess),
    expect: () => [isA<SubmitInProgress>(), isA<SubmitSucceeded>()],
    verify: (_) =>
        verify(() => users.updateAccess('u-1', _supervisorAccess)).called(1),
  );
}
