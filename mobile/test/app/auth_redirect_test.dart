import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/app/router/app_router.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';

import '../helpers/fake_auth.dart';

void main() {
  const signedIn = AuthSignedIn(testUser);

  test('waits on the splash page while the session is checked', () {
    expect(authRedirect(const AuthUnknown(), AppRoutes.home), AppRoutes.splash);
    expect(authRedirect(const AuthUnknown(), AppRoutes.splash), isNull);
    expect(
      authRedirect(const AuthUnavailable(NetworkFailure()), AppRoutes.login),
      AppRoutes.splash,
    );
  });

  test('sends a signed-out user to the sign-in page', () {
    expect(
      authRedirect(const AuthSignedOut(), AppRoutes.home),
      AppRoutes.login,
    );
    expect(authRedirect(const AuthSignedOut(), '/somewhere'), AppRoutes.login);
    expect(authRedirect(const AuthSignedOut(), AppRoutes.login), isNull);
  });

  test('keeps a signed-in user away from the splash and sign-in pages', () {
    expect(authRedirect(signedIn, AppRoutes.splash), AppRoutes.home);
    expect(authRedirect(signedIn, AppRoutes.login), AppRoutes.home);
  });

  test('lets a signed-in user open any other page', () {
    expect(authRedirect(signedIn, AppRoutes.home), isNull);
    expect(authRedirect(signedIn, '/does-not-exist'), isNull);
  });

  test(
    'keeps a user with a temporary password on the change-password page',
    () {
      const mustChange = AuthSignedIn(testUserWithTemporaryPassword);

      expect(
        authRedirect(mustChange, AppRoutes.home),
        AppRoutes.changePassword,
      );
      expect(
        authRedirect(mustChange, AppRoutes.login),
        AppRoutes.changePassword,
      );
      expect(authRedirect(mustChange, AppRoutes.changePassword), isNull);
      expect(authRedirect(signedIn, AppRoutes.changePassword), AppRoutes.home);
    },
  );

  test('sends a user without the permission to the forbidden page', () {
    const admin = AuthSignedIn(testAdmin);

    expect(authRedirect(signedIn, AppRoutes.users), AppRoutes.forbidden);
    expect(
      authRedirect(signedIn, '${AppRoutes.users}/42'),
      AppRoutes.forbidden,
    );
    expect(authRedirect(admin, AppRoutes.users), isNull);
    expect(authRedirect(signedIn, AppRoutes.forbidden), isNull);
  });
}
