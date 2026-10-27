import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/app.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/app/router/app_router.dart';
import 'package:lean_assistant/app/router/forbidden_page.dart';
import 'package:lean_assistant/app/router/not_found_page.dart';
import 'package:lean_assistant/features/admin/presentation/users_page.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fake_auth.dart';
import '../helpers/test_dependencies.dart';

void main() {
  late MockAuthBloc authBloc;
  late GoRouter router;

  setUp(registerTestDependencies);
  tearDown(getIt.reset);

  Future<void> pumpApp(WidgetTester tester, AuthState state) async {
    authBloc = authBlocIn(state);
    router = createRouter(authBloc);
    await tester.pumpWidget(
      LeanAssistantApp(router: router, authBloc: authBloc),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('unknown route shows the not found page', (tester) async {
    await pumpApp(tester, const AuthSignedIn(testUser));

    router.go('/does-not-exist');
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundPage), findsOneWidget);
  });

  testWidgets('the sign-out button asks the auth bloc to sign out', (
    tester,
  ) async {
    await pumpApp(tester, const AuthSignedIn(testUser));

    await tester.tap(find.byIcon(Icons.logout));

    verify(() => authBloc.add(const AuthSignOutRequested())).called(1);
  });

  testWidgets('an operator cannot reach the users page', (tester) async {
    await pumpApp(tester, const AuthSignedIn(testUser));

    expect(find.byIcon(Icons.manage_accounts_outlined), findsNothing);

    router.go(AppRoutes.users);
    await tester.pumpAndSettle();

    expect(find.byType(ForbiddenPage), findsOneWidget);
    expect(find.byType(UsersPage), findsNothing);
  });

  testWidgets('an admin opens the users page from home', (tester) async {
    await pumpApp(tester, const AuthSignedIn(testAdmin));

    await tester.tap(find.byIcon(Icons.manage_accounts_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(UsersPage), findsOneWidget);
  });
}
