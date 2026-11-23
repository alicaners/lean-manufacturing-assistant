import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/managed_user.dart';
import 'package:lean_assistant/features/admin/domain/plant.dart';
import 'package:lean_assistant/features/admin/presentation/access_options_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/access_options_state.dart';
import 'package:lean_assistant/features/admin/presentation/edit_access_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/edit_access_page.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockAccessOptions extends MockCubit<AccessOptionsState>
    implements AccessOptionsCubit {}

class _MockEditAccess extends MockCubit<SubmitState>
    implements EditAccessCubit {}

const _operatorOnPress = ManagedUser(
  id: 'u-1',
  userName: 'demo.operator',
  fullName: 'Demo Operatör',
  role: UserRole.operator,
  isActive: true,
  mustChangePassword: false,
  factoryId: 'p-1',
  lineId: 'l-1',
);

void main() {
  late _MockAccessOptions options;

  setUp(() {
    options = _MockAccessOptions();
    when(() => options.state).thenReturn(
      const AccessOptionsState(
        plantsStatus: OptionsStatus.ready,
        plants: [Plant(id: 'p-1', name: 'İzmir Fabrikası', code: 'DEMO-IZM')],
        linesStatus: OptionsStatus.ready,
        lines: [
          PlantLine(id: 'l-1', name: 'Pres Hattı 1', departmentName: 'Pres'),
        ],
      ),
    );
    when(() => options.loadPlants()).thenAnswer((_) async {});
    when(() => options.plantChanged(any())).thenAnswer((_) async {});

    final editAccess = _MockEditAccess();
    when(() => editAccess.state).thenReturn(const SubmitIdle());

    getIt
      ..registerFactory<AccessOptionsCubit>(() => options)
      ..registerFactory<EditAccessCubit>(() => editAccess);
  });

  tearDown(getIt.reset);

  testWidgets('starts from the user\'s current access', (tester) async {
    await tester.pumpApp(const EditAccessPage(user: _operatorOnPress));

    final role = tester.widget<DropdownButtonFormField<UserRole>>(
      find.byType(DropdownButtonFormField<UserRole>),
    );
    expect(role.initialValue, UserRole.operator);

    final plantAndLine = tester.widgetList<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(
      [for (final field in plantAndLine) field.initialValue],
      ['p-1', 'l-1'],
    );

    // The lines of the user's plant are asked for as soon as the page opens.
    verify(() => options.plantChanged('p-1')).called(1);
  });
}
