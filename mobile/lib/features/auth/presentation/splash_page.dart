import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lean_assistant/core/error/failure_message.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/error_view.dart';
import 'package:lean_assistant/core/widgets/loading_view.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';

/// Shown while the stored session is checked at start-up.
/// The router leaves this page by itself once the check is done.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) => switch (state) {
          AuthUnavailable(:final failure) => ErrorView(
            message: failure.message(l10n),
            onRetry: () =>
                context.read<AuthBloc>().add(const AuthCheckRequested()),
          ),
          _ => LoadingView(message: l10n.splashChecking),
        },
      ),
    );
  }
}
