import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/app/router/app_router.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/empty_view.dart';
import 'package:lean_assistant/core/widgets/primary_button.dart';
import 'package:lean_assistant/features/dashboard/presentation/server_status_card.dart';
import 'package:lean_assistant/features/dashboard/presentation/server_status_cubit.dart';

/// Temporary home page until the real dashboard is built.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider<ServerStatusCubit>(
      // A new cubit for each visit; BlocProvider closes it when the page is gone.
      create: (_) => getIt<ServerStatusCubit>()..check(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.appTitle)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const ServerStatusCard(),
              Expanded(
                child: EmptyView(
                  message: l10n.homeEmptyMessage,
                  icon: Icons.precision_manufacturing_outlined,
                ),
              ),
              PrimaryButton(
                label: l10n.homeGoToLogin,
                onPressed: () => context.push(AppRoutes.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
