import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/router/forbidden_page.dart';
import 'package:lean_assistant/app/router/not_found_page.dart';
import 'package:lean_assistant/app/router/stream_listenable.dart';
import 'package:lean_assistant/features/admin/presentation/users_page.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';
import 'package:lean_assistant/features/auth/domain/permission.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';
import 'package:lean_assistant/features/auth/presentation/change_password_page.dart';
import 'package:lean_assistant/features/auth/presentation/login_page.dart';
import 'package:lean_assistant/features/auth/presentation/splash_page.dart';
import 'package:lean_assistant/features/dashboard/presentation/home_page.dart';

/// All route paths in one place, so they are never typed as raw strings.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String login = '/login';
  static const String changePassword = '/change-password';
  static const String forbidden = '/forbidden';
  static const String users = '/users';
}

/// Builds the app's router. Every navigation, and every change of the
/// sign-in state, passes through [authRedirect].
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: StreamListenable(authBloc.stream),
    redirect: (context, state) => authRedirect(authBloc.state, state.uri.path),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.forbidden,
        builder: (context, state) => const ForbiddenPage(),
      ),
      GoRoute(
        path: AppRoutes.users,
        builder: (context, state) => const UsersPage(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
}

/// Pages a signed-in user has no reason to see.
const Set<String> _entryPages = {
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.changePassword,
};

/// Pages (and the pages under them) that only some roles may open.
/// The server checks every request as well; this only keeps users
/// away from screens that would fail for them.
const Map<String, Permission> _requiredPermissions = {
  AppRoutes.users: Permission.manageUsers,
};

/// Where the user should be instead of [location], or null to stay there.
///
/// While the session is being checked (or cannot be checked), only the
/// splash page is shown; signed-out users only see the sign-in page;
/// a user with a temporary password only sees the change-password page;
/// everyone else never sees those entry pages again, and is sent to the
/// forbidden page instead of a page their role may not open.
String? authRedirect(AuthState auth, String location) {
  return switch (auth) {
    AuthUnknown() ||
    AuthUnavailable() => location == AppRoutes.splash ? null : AppRoutes.splash,
    AuthSignedOut() => location == AppRoutes.login ? null : AppRoutes.login,
    AuthSignedIn(:final user) when user.mustChangePassword =>
      location == AppRoutes.changePassword ? null : AppRoutes.changePassword,
    AuthSignedIn(:final user) => _signedInRedirect(user, location),
  };
}

String? _signedInRedirect(CurrentUser user, String location) {
  if (_entryPages.contains(location)) return AppRoutes.home;

  final required = _requiredPermission(location);
  if (required != null && !user.role.can(required)) {
    return AppRoutes.forbidden;
  }

  return null;
}

/// The permission [location] needs, also for pages under it
/// (e.g. `/users/42` needs the same permission as `/users`).
Permission? _requiredPermission(String location) {
  for (final MapEntry(:key, :value) in _requiredPermissions.entries) {
    if (location == key || location.startsWith('$key/')) return value;
  }
  return null;
}
