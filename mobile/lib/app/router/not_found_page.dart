import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/router/app_router.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/error_view.dart';

/// Shown when the user opens a route that does not exist.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: ErrorView(
        title: l10n.notFoundTitle,
        message: l10n.notFoundMessage,
        actionLabel: l10n.commonGoHome,
        onRetry: () => context.go(AppRoutes.home),
      ),
    );
  }
}
