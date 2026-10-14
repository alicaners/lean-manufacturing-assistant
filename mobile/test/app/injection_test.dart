import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/di/injection.dart';

void main() {
  setUp(configureDependencies);
  tearDown(getIt.reset);

  test('router is registered as a lazy singleton', () {
    final first = getIt<GoRouter>();
    final second = getIt<GoRouter>();

    expect(identical(first, second), isTrue);
  });
}
