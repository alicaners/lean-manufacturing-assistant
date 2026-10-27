import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/app/router/app_router.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/empty_view.dart';
import 'package:lean_assistant/features/auth/domain/permission.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';
import 'package:lean_assistant/features/auth/presentation/user_role_label.dart';
import 'package:lean_assistant/features/dashboard/presentation/server_status_card.dart';
import 'package:lean_assistant/features/dashboard/presentation/server_status_cubit.dart';

/// Temporary home page until the real dashboard is built.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = switch (context.watch<AuthBloc>().state) {
      AuthSignedIn(:final user) => user,
      _ => null,
    };

    return BlocProvider<ServerStatusCubit>(
      // A new cubit for each visit; BlocProvider closes it when the page is gone.
      create: (_) => getIt<ServerStatusCubit>()..check(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          actions: [
            IconButton(
              tooltip: l10n.homeSignOut,
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthSignOutRequested()),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null) ...[
                Text(
                  l10n.homeWelcome(user.fullName),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(l10n.homeRole(user.role.label(l10n))),
                const SizedBox(height: 16),
                // Only roles that may manage users see the way in.
                if (user.role.can(Permission.manageUsers)) ...[
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.users),
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: Text(l10n.homeManageUsers),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
              const ServerStatusCard(),
              Expanded(
                child: EmptyView(
                  message: l10n.homeEmptyMessage,
                  icon: Icons.precision_manufacturing_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
