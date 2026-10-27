import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/app.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/app/router/app_router.dart';
import 'package:lean_assistant/app/router/not_found_page.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fake_auth.dart';
import '../helpers/test_dependencies.dart';

void main() {
  late MockAuthBloc authBloc;
  late GoRouter router;

  setUp(() {
    registerTestDependencies();
    authBloc = authBlocIn(const AuthSignedIn(testUser));
    router = createRouter(authBloc);
  });
  tearDown(getIt.reset);

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      LeanAssistantApp(router: router, authBloc: authBloc),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('unknown route shows the not found page', (tester) async {
    await pumpApp(tester);

    router.go('/does-not-exist');
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundPage), findsOneWidget);
  });

  testWidgets('the sign-out button asks the auth bloc to sign out', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.logout));

    verify(() => authBloc.add(const AuthSignOutRequested())).called(1);
  });
}
