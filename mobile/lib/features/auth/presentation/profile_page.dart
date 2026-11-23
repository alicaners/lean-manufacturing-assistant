import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/router/app_router.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/loading_view.dart';
import 'package:lean_assistant/features/admin/presentation/user_avatar.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';
import 'package:lean_assistant/features/auth/presentation/user_role_label.dart';

/// The signed-in user's own page: who they are, their password, signing out.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _changePassword(BuildContext context) async {
    // Read everything that needs the context before waiting.
    final messenger = ScaffoldMessenger.of(context);
    final changedMessage = context.l10n.profilePasswordChanged;

    final changed = await context.push<bool>(AppRoutes.changeOwnPassword);
    if (changed != true) return;

    messenger.showSnackBar(SnackBar(content: Text(changedMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = switch (context.watch<AuthBloc>().state) {
      AuthSignedIn(:final user) => user,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      // Null only for a moment after signing out, before the router moves on.
      body: user == null
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(child: UserAvatar(user.fullName, radius: 36)),
                const SizedBox(height: 12),
                Text(
                  user.fullName,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${user.userName} · ${user.role.label(l10n)}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profilePasswordSection,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.profilePasswordInfo),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _changePassword(context),
                          icon: const Icon(Icons.key_outlined),
                          label: Text(l10n.profileChangePassword),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => context.read<AuthBloc>().add(
                    const AuthSignOutRequested(),
                  ),
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.homeSignOut),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
    );
  }
}
