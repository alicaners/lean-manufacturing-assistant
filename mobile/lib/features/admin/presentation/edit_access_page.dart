import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/failure_message.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/primary_button.dart';
import 'package:lean_assistant/features/admin/domain/managed_user.dart';
import 'package:lean_assistant/features/admin/domain/user_access.dart';
import 'package:lean_assistant/features/admin/presentation/access_fields.dart';
import 'package:lean_assistant/features/admin/presentation/access_options_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/edit_access_cubit.dart';

/// Changes a user's role, plant and line. Closes itself with `true` once saved.
class EditAccessPage extends StatelessWidget {
  const EditAccessPage({super.key, required this.user});

  final ManagedUser user;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AccessOptionsCubit>(
          create: (_) => getIt<AccessOptionsCubit>()..loadPlants(),
        ),
        BlocProvider<EditAccessCubit>(create: (_) => getIt<EditAccessCubit>()),
      ],
      child: _EditAccessForm(user: user),
    );
  }
}

class _EditAccessForm extends StatefulWidget {
  const _EditAccessForm({required this.user});

  final ManagedUser user;

  @override
  State<_EditAccessForm> createState() => _EditAccessFormState();
}

class _EditAccessFormState extends State<_EditAccessForm> {
  final _formKey = GlobalKey<FormState>();
  late UserAccess _access = widget.user.access;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<EditAccessCubit>().save(widget.user.id, _access);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = widget.user;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.userDetailEditAccess)),
      body: BlocConsumer<EditAccessCubit, SubmitState>(
        listener: (context, submit) {
          if (submit is SubmitSucceeded) context.pop(true);
        },
        builder: (context, submit) {
          final error = switch (submit) {
            SubmitFailed(failure: ForbiddenFailure()) =>
              l10n.userFormOutsideScope,
            SubmitFailed(:final failure) => failure.message(l10n),
            _ => null,
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${user.fullName} (${user.userName})',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.editAccessInfo, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 24),
                  AccessFields(
                    initial: user.access,
                    onChanged: (access) => _access = access,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      error,
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: l10n.editAccessSave,
                    isLoading: submit is SubmitInProgress,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
