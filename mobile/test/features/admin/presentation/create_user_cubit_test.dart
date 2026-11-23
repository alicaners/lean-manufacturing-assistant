import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/new_user.dart';
import 'package:lean_assistant/features/admin/domain/organization_repository.dart';
import 'package:lean_assistant/features/admin/domain/plant.dart';
import 'package:lean_assistant/features/admin/domain/user_admin_repository.dart';
import 'package:lean_assistant/features/admin/presentation/create_user_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/create_user_state.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_users.dart';

class _MockUsers extends Mock implements UserAdminRepository {}

class _MockOrganization extends Mock implements OrganizationRepository {}

const _plant = Plant(id: 'p-1', name: 'İzmir Fabrikası', code: 'DEMO-IZM');

const _line = PlantLine(
  id: 'l-1',
  name: 'Pres Hattı 1',
  departmentName: 'Pres',
);

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
  late _MockOrganization organization;

  setUpAll(() => registerFallbackValue(_newUser));

  setUp(() {
    users = _MockUsers();
    organization = _MockOrganization();
  });

  CreateUserCubit build() => CreateUserCubit(users, organization);

  blocTest<CreateUserCubit, CreateUserState>(
    'loads the plants',
    setUp: () =>
        when(() => organization.plants())
            .thenAnswer((_) async => const Ok([_plant])),
    build: build,
    act: (cubit) => cubit.loadPlants(),
    expect: () => [
      isA<CreateUserState>().having(
        (state) => state.plantsStatus,
        'plantsStatus',
        OptionsStatus.loading,
      ),
      isA<CreateUserState>()
          .having(
            (state) => state.plantsStatus,
            'plantsStatus',
            OptionsStatus.ready,
          )
          .having((state) => state.plants, 'plants', [_plant]),
    ],
  );

  blocTest<CreateUserCubit, CreateUserState>(
    'loads the lines of the chosen plant',
    setUp: () =>
        when(() => organization.lines('p-1'))
            .thenAnswer((_) async => const Ok([_line])),
    build: build,
    act: (cubit) => cubit.plantChanged('p-1'),
    expect: () => [
      isA<CreateUserState>().having(
        (state) => state.linesStatus,
        'linesStatus',
        OptionsStatus.loading,
      ),
      isA<CreateUserState>()
          .having(
            (state) => state.linesStatus,
            'linesStatus',
            OptionsStatus.ready,
          )
          .having((state) => state.lines, 'lines', [_line]),
    ],
  );

  blocTest<CreateUserCubit, CreateUserState>(
    'reports success once the user is created',
    setUp: () =>
        when(() => users.create(any()))
            .thenAnswer((_) async => const Ok(operatorUser)),
    build: build,
    act: (cubit) => cubit.submit(_newUser),
    expect: () => [
      isA<CreateUserState>().having(
        (state) => state.submit,
        'submit',
        isA<SubmitInProgress>(),
      ),
      isA<CreateUserState>().having(
        (state) => state.submit,
        'submit',
        isA<SubmitSucceeded>(),
      ),
    ],
    verify: (_) => verify(() => users.create(_newUser)).called(1),
  );

  blocTest<CreateUserCubit, CreateUserState>(
    'shows why the user could not be created',
    setUp: () =>
        when(() => users.create(any()))
            .thenAnswer((_) async => const Err(ConflictFailure())),
    build: build,
    act: (cubit) => cubit.submit(_newUser),
    expect: () => [
      isA<CreateUserState>().having(
        (state) => state.submit,
        'submit',
        isA<SubmitInProgress>(),
      ),
      isA<CreateUserState>().having(
        (state) => state.submit,
        'submit',
        isA<SubmitFailed>().having(
          (submit) => submit.failure,
          'failure',
          isA<ConflictFailure>(),
        ),
      ),
    ],
  );
}
