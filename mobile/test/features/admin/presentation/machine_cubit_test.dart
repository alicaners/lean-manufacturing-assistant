import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/machine_detail.dart';
import 'package:lean_assistant/features/admin/domain/organization_repository.dart';
import 'package:lean_assistant/features/admin/presentation/machine_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/machine_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrganization extends Mock implements OrganizationRepository {}

const _machine = MachineDetail(
  id: 'm-1',
  name: 'Pres 1',
  code: 'PR-01',
  qrCode: 'abcdefghijklmnopqrstuv',
);

const _withNewCode = MachineDetail(
  id: 'm-1',
  name: 'Pres 1',
  code: 'PR-01',
  qrCode: 'vutsrqponmlkjihgfedcba',
);

void main() {
  late _MockOrganization organization;

  setUp(() => organization = _MockOrganization());

  blocTest<MachineCubit, MachineState>(
    'loads the machine',
    setUp: () =>
        when(() => organization.machine('m-1'))
            .thenAnswer((_) async => const Ok(_machine)),
    build: () => MachineCubit(organization),
    act: (cubit) => cubit.load('m-1'),
    expect: () => [
      isA<MachineState>()
          .having((state) => state.status, 'status', MachineStatus.ready)
          .having((state) => state.machine, 'machine', _machine),
    ],
  );

  blocTest<MachineCubit, MachineState>(
    'shows the new QR code once it is made',
    setUp: () =>
        when(() => organization.regenerateQr('m-1'))
            .thenAnswer((_) async => const Ok(_withNewCode)),
    build: () => MachineCubit(organization),
    seed: () =>
        const MachineState(status: MachineStatus.ready, machine: _machine),
    act: (cubit) => cubit.regenerateQr(),
    expect: () => [
      isA<MachineState>().having(
        (state) => state.regenerate,
        'regenerate',
        isA<SubmitInProgress>(),
      ),
      isA<MachineState>()
          .having(
            (state) => state.regenerate,
            'regenerate',
            isA<SubmitSucceeded>(),
          )
          .having(
            (state) => state.machine?.qrCode,
            'qrCode',
            'vutsrqponmlkjihgfedcba',
          ),
    ],
  );
}
