import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/core/error/failure_message.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/core/forms/validators.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/app_text_field.dart';
import 'package:lean_assistant/core/widgets/error_view.dart';
import 'package:lean_assistant/core/widgets/loading_view.dart';
import 'package:lean_assistant/features/admin/domain/managed_user.dart';
import 'package:lean_assistant/features/admin/presentation/user_avatar.dart';
import 'package:lean_assistant/features/admin/presentation/user_detail_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/user_detail_state.dart';
import 'package:lean_assistant/features/auth/domain/password_rules.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';
import 'package:lean_assistant/features/auth/presentation/user_role_label.dart';

/// One user, with the actions an admin can take on them.
class UserDetailPage extends StatelessWidget {
  const UserDetailPage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserDetailCubit>(
      create: (_) => getIt<UserDetailCubit>()..load(userId),
      child: _UserDetailView(userId: userId),
    );
  }
}

class _UserDetailView extends StatelessWidget {
  const _UserDetailView({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<UserDetailCubit>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.userDetailTitle)),
      body: BlocConsumer<UserDetailCubit, UserDetailState>(
        listenWhen: (previous, current) => previous.action != current.action,
        listener: (context, state) {
          final message = _messageFor(state, l10n);
          if (message != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          if (state.status == UserDetailStatus.failed) {
            return ErrorView(
              message: state.loadFailure?.message(l10n),
              onRetry: () => cubit.load(userId),
            );
          }

          final user = state.user;
          if (user == null) return const LoadingView();

          return _UserDetails(
            user: user,
            busy: state.action is SubmitInProgress,
          );
        },
      ),
    );
  }

  /// What to tell the admin once an action has finished.
  static String? _messageFor(UserDetailState state, AppLocalizations l10n) {
    return switch ((state.action, state.lastAction)) {
      (SubmitSucceeded(), UserAction.activate) => l10n.userDetailActivated,
      (SubmitSucceeded(), UserAction.deactivate) => l10n.userDetailDeactivated,
      (SubmitSucceeded(), UserAction.resetPassword) =>
        l10n.userDetailPasswordReset,
      (SubmitFailed(:final failure), _) => failure.message(l10n),
      _ => null,
    };
  }
}

class _UserDetails extends StatelessWidget {
  const _UserDetails({required this.user, required this.busy});

  final ManagedUser user;

  /// An action is on its way; buttons wait until it finishes.
  final bool busy;

  Future<void> _confirmDeactivate(BuildContext context) async {
    final cubit = context.read<UserDetailCubit>();
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.userDetailDeactivateTitle),
        content: Text(l10n.userDetailDeactivateMessage(user.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.userDetailDeactivate),
          ),
        ],
      ),
    );

    if (confirmed == true) await cubit.setActive(active: false);
  }

  Future<void> _resetPassword(BuildContext context) async {
    final cubit = context.read<UserDetailCubit>();

    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _ResetPasswordDialog(),
    );

    if (password != null) await cubit.resetPassword(password);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<UserDetailCubit>();

    // An admin may not deactivate or reset themselves here.
    final myId = switch (context.watch<AuthBloc>().state) {
      AuthSignedIn(user: final me) => me.id,
      _ => null,
    };
    final isSelf = user.id == myId;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (busy) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
        ],
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
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            Chip(
              label: Text(
                user.isActive ? l10n.usersActive : l10n.usersInactive,
              ),
            ),
            if (user.mustChangePassword)
              Chip(
                avatar: const Icon(Icons.key_outlined, size: 18),
                label: Text(l10n.userDetailTemporaryPassword),
              ),
          ],
        ),
        const SizedBox(height: 32),
        if (isSelf)
          Text(l10n.userDetailSelfInfo, textAlign: TextAlign.center)
        else ...[
          _Section(
            title: l10n.userDetailAccountSection,
            info: user.isActive
                ? l10n.userDetailActiveInfo
                : l10n.userDetailInactiveInfo,
            action: user.isActive
                ? OutlinedButton.icon(
                    onPressed: busy ? null : () => _confirmDeactivate(context),
                    icon: const Icon(Icons.person_off_outlined),
                    label: Text(l10n.userDetailDeactivate),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  )
                : FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => cubit.setActive(active: true),
                    icon: const Icon(Icons.person_outline),
                    label: Text(l10n.userDetailActivate),
                  ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: l10n.userDetailPasswordSection,
            info: l10n.userDetailPasswordInfo,
            action: OutlinedButton.icon(
              onPressed: busy ? null : () => _resetPassword(context),
              icon: const Icon(Icons.key_outlined),
              label: Text(l10n.userDetailResetPassword),
            ),
          ),
        ],
      ],
    );
  }
}

/// A card with a title, an explanation and one action.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.info,
    required this.action,
  });

  final String title;
  final String info;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(info),
            const SizedBox(height: 16),
            action,
          ],
        ),
      ),
    );
  }
}

/// Asks for the new temporary password; closes with it, or with null.
class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog();

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.userDetailResetPasswordTitle),
      content: Form(
        key: _formKey,
        child: AppTextField(
          label: l10n.userFormTemporaryPassword,
          controller: _password,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          validator: Validators.password(
            l10n,
            minLength: PasswordRules.minimumLength,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.userDetailResetPasswordSubmit),
        ),
      ],
    );
  }
}
