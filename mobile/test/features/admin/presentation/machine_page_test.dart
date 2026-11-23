import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/features/admin/domain/machine_detail.dart';
import 'package:lean_assistant/features/admin/presentation/machine_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/machine_page.dart';
import 'package:lean_assistant/features/admin/presentation/machine_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../helpers/pump_app.dart';

class _MockMachineCubit extends MockCubit<MachineState>
    implements MachineCubit {}

void main() {
  late _MockMachineCubit cubit;

  setUp(() {
    cubit = _MockMachineCubit();
    when(() => cubit.load(any())).thenAnswer((_) async {});
    when(() => cubit.state).thenReturn(
      const MachineState(
        status: MachineStatus.ready,
        machine: MachineDetail(
          id: 'm-1',
          name: 'Pres 1',
          code: 'PR-01',
          qrCode: 'abcdefghijklmnopqrstuv',
        ),
      ),
    );
    getIt.registerFactory<MachineCubit>(() => cubit);
  });

  tearDown(getIt.reset);

  testWidgets('shows the machine and its QR code', (tester) async {
    await tester.pumpApp(const MachinePage(machineId: 'm-1'));

    expect(find.text('Pres 1'), findsOneWidget);
    expect(find.text('PR-01'), findsOneWidget);

        // What the code holds is tested in machine_qr_test.dart.
    expect(find.byType(QrImageView), findsOneWidget);   
  });
}

