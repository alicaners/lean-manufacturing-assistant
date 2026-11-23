import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/features/admin/domain/plant.dart';
import 'package:lean_assistant/features/admin/domain/plant_tree.dart';
import 'package:lean_assistant/features/admin/presentation/organization_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/organization_page.dart';
import 'package:lean_assistant/features/admin/presentation/organization_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockOrganizationCubit extends MockCubit<OrganizationState>
    implements OrganizationCubit {}

void main() {
  late _MockOrganizationCubit cubit;

  setUp(() {
    cubit = _MockOrganizationCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    when(() => cubit.state).thenReturn(
      const OrganizationState(
        status: OrganizationStatus.ready,
        plants: [Plant(id: 'p-1', name: 'İzmir Fabrikası', code: 'DEMO-IZM')],
        plantId: 'p-1',
        tree: PlantTree(
          id: 'p-1',
          name: 'İzmir Fabrikası',
          code: 'DEMO-IZM',
          departments: [
            DepartmentNode(
              id: 'd-1',
              name: 'Pres',
              lines: [
                LineNode(
                  id: 'l-1',
                  name: 'Pres Hattı 1',
                  machines: [
                    MachineNode(id: 'm-1', name: 'Pres 1', code: 'PR-01'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
    getIt.registerFactory<OrganizationCubit>(() => cubit);
  });

  tearDown(getIt.reset);

  testWidgets('opens a department, then a line, to show its machines', (
    tester,
  ) async {
    await tester.pumpApp(const OrganizationPage());

    expect(find.text('Pres'), findsOneWidget);
    expect(find.text('1 hat'), findsOneWidget);
    expect(find.text('Pres Hattı 1'), findsNothing);

    await tester.tap(find.text('Pres'));
    await tester.pumpAndSettle();
    expect(find.text('Pres Hattı 1'), findsOneWidget);

    await tester.tap(find.text('Pres Hattı 1'));
    await tester.pumpAndSettle();
    expect(find.text('Pres 1'), findsOneWidget);
    expect(find.text('PR-01'), findsOneWidget);
  });
}
