import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/app.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/app/router/app_router.dart';
import 'package:lean_assistant/app/router/not_found_page.dart';
import 'package:lean_assistant/features/auth/presentation/login_page.dart';
import 'package:lean_assistant/features/dashboard/presentation/home_page.dart';

import '../helpers/test_dependencies.dart';

void main() {
  late GoRouter router;

  setUp(() {
    registerTestDependencies();
    router = createRouter();
  });
  tearDown(getIt.reset);

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(LeanAssistantApp(router: router));
    await tester.pumpAndSettle();
  }

  testWidgets('home button opens the login page and back returns home', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('unknown route shows the not found page', (tester) async {
    await pumpApp(tester);

    router.go('/does-not-exist');
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundPage), findsOneWidget);
  });
}
