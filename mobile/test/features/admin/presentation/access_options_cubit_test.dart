import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/features/admin/domain/organization_repository.dart';
import 'package:lean_assistant/features/admin/domain/plant.dart';
import 'package:lean_assistant/features/admin/presentation/access_options_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/access_options_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrganization extends Mock implements OrganizationRepository {}

const _plant = Plant(id: 'p-1', name: 'İzmir Fabrikası', code: 'DEMO-IZM');

const _line = PlantLine(
  id: 'l-1',
  name: 'Pres Hattı 1',
  departmentName: 'Pres',
);

void main() {
  late _MockOrganization organization;

  setUp(() => organization = _MockOrganization());

  blocTest<AccessOptionsCubit, AccessOptionsState>(
    'loads the plants',
    setUp: () =>
        when(() => organization.plants())
            .thenAnswer((_) async => const Ok([_plant])),
    build: () => AccessOptionsCubit(organization),
    act: (cubit) => cubit.loadPlants(),
    expect: () => [
      isA<AccessOptionsState>().having(
        (state) => state.plantsStatus,
        'plantsStatus',
        OptionsStatus.loading,
      ),
      isA<AccessOptionsState>()
          .having(
            (state) => state.plantsStatus,
            'plantsStatus',
            OptionsStatus.ready,
          )
          .having((state) => state.plants, 'plants', [_plant]),
    ],
  );

  blocTest<AccessOptionsCubit, AccessOptionsState>(
    'loads the lines of the chosen plant',
    setUp: () =>
        when(() => organization.lines('p-1'))
            .thenAnswer((_) async => const Ok([_line])),
    build: () => AccessOptionsCubit(organization),
    act: (cubit) => cubit.plantChanged('p-1'),
    expect: () => [
      isA<AccessOptionsState>().having(
        (state) => state.linesStatus,
        'linesStatus',
        OptionsStatus.loading,
      ),
      isA<AccessOptionsState>()
          .having(
            (state) => state.linesStatus,
            'linesStatus',
            OptionsStatus.ready,
          )
          .having((state) => state.lines, 'lines', [_line]),
    ],
  );
}
