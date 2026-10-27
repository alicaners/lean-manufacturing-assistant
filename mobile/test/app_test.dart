import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/app/app.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/app/router/app_router.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';
import 'package:lean_assistant/features/auth/presentation/login_page.dart';
import 'package:lean_assistant/features/dashboard/presentation/home_page.dart';

import 'helpers/fake_auth.dart';
import 'helpers/test_dependencies.dart';

void main() {
  setUp(registerTestDependencies);
  tearDown(getIt.reset);

  Future<void> startApp(WidgetTester tester, AuthState state) async {
    final authBloc = authBlocIn(state);
    await tester.pumpWidget(
      LeanAssistantApp(router: createRouter(authBloc), authBloc: authBloc),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a signed-in user starts on the home page', (tester) async {
    await startApp(tester, const AuthSignedIn(testUser));

    expect(find.byType(HomePage), findsOneWidget);
    // The test device's language may be English or Turkish: check the name only.
    expect(find.textContaining('Demo Operatör'), findsOneWidget);
  });

  testWidgets('a signed-out user starts on the sign-in page', (tester) async {
    await startApp(tester, const AuthSignedOut());

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
