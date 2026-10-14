import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/core/config/app_config.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: 'http://test.local',
  );

  setUp(() => configureDependencies(config));
  tearDown(getIt.reset);

  test('router is registered as a lazy singleton', () {
    final first = getIt<GoRouter>();
    final second = getIt<GoRouter>();

    expect(identical(first, second), isTrue);
  });

  test('dio uses the base url of the active flavor', () {
    expect(getIt<Dio>().options.baseUrl, 'http://test.local');
  });
}
