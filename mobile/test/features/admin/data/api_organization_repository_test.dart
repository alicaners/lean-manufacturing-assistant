import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/api_client.dart';
import 'package:lean_assistant/features/admin/data/api_organization_repository.dart';
import 'package:lean_assistant/features/admin/domain/plant.dart';

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
}
