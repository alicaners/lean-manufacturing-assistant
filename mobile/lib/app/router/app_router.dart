import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/router/not_found_page.dart';
import 'package:lean_assistant/features/auth/presentation/login_page.dart';
import 'package:lean_assistant/features/dashboard/presentation/home_page.dart';

/// All route paths in one place, so they are never typed as raw strings.
abstract final class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
}

/// Builds the app's router. Auth redirects will be added in stage 4.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
}
