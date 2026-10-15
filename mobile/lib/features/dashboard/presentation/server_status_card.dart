import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lean_assistant/core/error/failure_message.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/features/dashboard/domain/server_health.dart';
import 'package:lean_assistant/features/dashboard/presentation/server_status_cubit.dart';
import 'package:lean_assistant/features/dashboard/presentation/server_status_state.dart';

/// Shows whether the backend is reachable, with a button to check again.
class ServerStatusCard extends StatelessWidget {
  const ServerStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;

    return BlocBuilder<ServerStatusCubit, ServerStatusState>(
      builder: (context, state) {
        final (Widget leading, String subtitle) = switch (state) {
          ServerStatusLoading() => (
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            l10n.serverStatusChecking,
          ),
          ServerStatusOnline(health: ServerHealth.healthy) => (
            Icon(Icons.cloud_done_outlined, color: colors.primary),
            l10n.serverStatusOnline,
          ),
          ServerStatusOnline(health: ServerHealth.degraded) => (
            Icon(Icons.cloud_outlined, color: colors.tertiary),
            l10n.serverStatusDegraded,
          ),
          ServerStatusOffline(:final failure) => (
            Icon(Icons.cloud_off_outlined, color: colors.error),
            failure.message(l10n),
          ),
        };

        return Card(
          child: ListTile(
            leading: leading,
            title: Text(l10n.serverStatusTitle),
            subtitle: Text(subtitle),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.serverStatusRefresh,
              onPressed: state is ServerStatusLoading
                  ? null
                  : () => context.read<ServerStatusCubit>().check(),
            ),
          ),
        );
      },
    );
  }
}
