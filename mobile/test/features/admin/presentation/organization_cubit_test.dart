import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/organization_repository.dart';
import 'package:lean_assistant/features/admin/domain/plant.dart';
import 'package:lean_assistant/features/admin/domain/plant_tree.dart';
import 'package:lean_assistant/features/admin/presentation/organization_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/organization_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrganization extends Mock implements OrganizationRepository {}

const _plant = Plant(id: 'p-1', name: 'İzmir Fabrikası', code: 'DEMO-IZM');

const _emptyTree = PlantTree(
  id: 'p-1',
  name: 'İzmir Fabrikası',
  code: 'DEMO-IZM',
  departments: [DepartmentNode(id: 'd-1', name: 'Pres', lines: [])],
);

const _treeWithLine = PlantTree(
  id: 'p-1',
  name: 'İzmir Fabrikası',
  code: 'DEMO-IZM',
  departments: [
    DepartmentNode(
      id: 'd-1',
      name: 'Pres',
      lines: [LineNode(id: 'l-1', name: 'Pres Hattı 1', machines: [])],
    ),
  ],
);

const _loaded = OrganizationState(
  status: OrganizationStatus.ready,
  plants: [_plant],
  plantId: 'p-1',
  tree: _emptyTree,
);

void main() {
  late _MockOrganization organization;

  setUp(() => organization = _MockOrganization());

  blocTest<OrganizationCubit, OrganizationState>(
    'shows the tree of the first plant',
    setUp: () {
      when(() => organization.plants())
          .thenAnswer((_) async => const Ok([_plant]));
      when(() => organization.tree('p-1'))
          .thenAnswer((_) async => const Ok(_emptyTree));
    },
    build: () => OrganizationCubit(organization),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<OrganizationState>()
          .having((state) => state.plantId, 'plantId', 'p-1')
          .having(
            (state) => state.status,
            'status',
            OrganizationStatus.loading,
          ),
      isA<OrganizationState>()
          .having((state) => state.status, 'status', OrganizationStatus.ready)
          .having((state) => state.tree, 'tree', _emptyTree),
    ],
  );

  blocTest<OrganizationCubit, OrganizationState>(
    'reads the tree again after adding a line',
    setUp: () {
      when(() => organization.addLine('d-1', 'Pres Hattı 1'))
          .thenAnswer((_) async => const Ok<void>(null));
      when(() => organization.tree('p-1'))
          .thenAnswer((_) async => const Ok(_treeWithLine));
    },
    build: () => OrganizationCubit(organization),
    seed: () => _loaded,
    act: (cubit) => cubit.addLine('d-1', 'Pres Hattı 1'),
    expect: () => [
      isA<OrganizationState>().having(
        (state) => state.change,
        'change',
        isA<SubmitInProgress>(),
      ),
      isA<OrganizationState>()
          .having((state) => state.change, 'change', isA<SubmitSucceeded>())
          .having((state) => state.tree, 'tree', _treeWithLine),
    ],
  );

  blocTest<OrganizationCubit, OrganizationState>(
    'keeps the tree when a name is already taken',
    setUp: () =>
        when(() => organization.addDepartment('p-1', 'Pres'))
            .thenAnswer((_) async => const Err(ConflictFailure())),
    build: () => OrganizationCubit(organization),
    seed: () => _loaded,
    act: (cubit) => cubit.addDepartment('Pres'),
    expect: () => [
      isA<OrganizationState>().having(
        (state) => state.change,
        'change',
        isA<SubmitInProgress>(),
      ),
      isA<OrganizationState>()
          .having((state) => state.change, 'change', isA<SubmitFailed>())
          .having((state) => state.tree, 'tree', _emptyTree),
    ],
    verify: (_) => verifyNever(() => organization.tree(any())),
  );
}
