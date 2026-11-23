import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/api_client.dart';
import 'package:lean_assistant/features/admin/data/api_organization_repository.dart';
import 'package:lean_assistant/features/admin/domain/machine_detail.dart';
import 'package:lean_assistant/features/admin/domain/plant.dart';
import 'package:lean_assistant/features/admin/domain/plant_tree.dart';

import '../../../helpers/fake_json_server.dart';

void main() {
  test('reads the plants the user may see', () async {
    final server = FakeJsonServer(
      200,
      '[{"id":"p-1","name":"İzmir Fabrikası","code":"DEMO-IZM"}]',
    );

    final result = await ApiOrganizationRepository(ApiClient(dioFor(server)))
        .plants();

    expect(server.requests.single.path, '/api/factories');
    expect((result as Ok<List<Plant>>).value.single.code, 'DEMO-IZM');
  });

  test('lists every line of a plant with its department', () async {
    final server = FakeJsonServer(
      200,
      '{"id":"p-1","name":"İzmir Fabrikası","code":"DEMO-IZM","departments":['
      '{"id":"d-1","name":"Pres","lines":['
      '{"id":"l-1","name":"Pres Hattı 1","machines":[]},'
      '{"id":"l-2","name":"Pres Hattı 2","machines":[]}]},'
      '{"id":"d-2","name":"Montaj","lines":['
      '{"id":"l-3","name":"Montaj Hattı","machines":[]}]}]}',
    );

    final result = await ApiOrganizationRepository(ApiClient(dioFor(server)))
        .lines('p-1');

    expect(server.requests.single.path, '/api/factories/p-1/tree');
    expect(
      [
        for (final line in (result as Ok<List<PlantLine>>).value)
          '${line.departmentName} · ${line.name}',
      ],
      ['Pres · Pres Hattı 1', 'Pres · Pres Hattı 2', 'Montaj · Montaj Hattı'],
    );
  });

  test('reads a plant\'s whole tree', () async {
    final server = FakeJsonServer(
      200,
      '{"id":"p-1","name":"İzmir Fabrikası","code":"DEMO-IZM","departments":['
      '{"id":"d-1","name":"Pres","lines":['
      '{"id":"l-1","name":"Pres Hattı 1","machines":['
      '{"id":"m-1","name":"Pres 1","code":"PR-01"}]}]}]}',
    );

    final result = await ApiOrganizationRepository(ApiClient(dioFor(server)))
        .tree('p-1');

    final tree = (result as Ok<PlantTree>).value;
    final line = tree.departments.single.lines.single;
    expect(tree.code, 'DEMO-IZM');
    expect(line.name, 'Pres Hattı 1');
    expect(line.machines.single.code, 'PR-01');
  });

  test('adds a machine to a line with its code', () async {
    final server = FakeJsonServer(201, '{}');

    final result = await ApiOrganizationRepository(ApiClient(dioFor(server)))
        .addMachine('l-1', name: 'Pres 4', code: 'PR-04');

    expect(server.requests.single.method, 'POST');
    expect(server.requests.single.path, '/api/lines/l-1/machines');
    expect(server.requests.single.data, {'name': 'Pres 4', 'code': 'PR-04'});
    expect(result, isA<Ok<void>>());
  });

  test('renames a line', () async {
    final server = FakeJsonServer(200, '{}');

    await ApiOrganizationRepository(ApiClient(dioFor(server)))
        .rename(TreeNodeKind.line, 'l-1', 'Pres Hattı A');

    expect(server.requests.single.method, 'PUT');
    expect(server.requests.single.path, '/api/lines/l-1');
    expect(server.requests.single.data, {'name': 'Pres Hattı A'});
  });

  test('reads one machine with its QR code', () async {
    final server = FakeJsonServer(
      200,
      '{"id":"m-1","factoryId":"p-1","lineId":"l-1","name":"Pres 1",'
      '"code":"PR-01","qrCode":"abcdefghijklmnopqrstuv"}',
    );

    final result = await ApiOrganizationRepository(ApiClient(dioFor(server)))
        .machine('m-1');

    expect(server.requests.single.path, '/api/machines/m-1');
    final machine = (result as Ok<MachineDetail>).value;
    expect(machine.code, 'PR-01');
    expect(machine.qrCode, 'abcdefghijklmnopqrstuv');
  });

  test('asks for a new QR code', () async {
    final server = FakeJsonServer(
      200,
      '{"id":"m-1","factoryId":"p-1","lineId":"l-1","name":"Pres 1",'
      '"code":"PR-01","qrCode":"vutsrqponmlkjihgfedcba"}',
    );

    final result = await ApiOrganizationRepository(ApiClient(dioFor(server)))
        .regenerateQr('m-1');

    expect(server.requests.single.method, 'POST');
    expect(server.requests.single.path, '/api/machines/m-1/regenerate-qr');
    expect(
      (result as Ok<MachineDetail>).value.qrCode,
      'vutsrqponmlkjihgfedcba',
    );
  });
}
