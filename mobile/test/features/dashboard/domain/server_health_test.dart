import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/features/dashboard/domain/server_health.dart';

void main() {
  test('parses the statuses ASP.NET Core returns with HTTP 200', () {
    expect(ServerHealth.parse('Healthy'), ServerHealth.healthy);
    expect(ServerHealth.parse('Degraded'), ServerHealth.degraded);
  });

  test('throws FormatException for an unexpected body', () {
    expect(() => ServerHealth.parse('Unhealthy'), throwsFormatException);
    expect(() => ServerHealth.parse(null), throwsFormatException);
  });
}
