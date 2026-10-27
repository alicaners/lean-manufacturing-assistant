import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/failure_message.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/core/forms/validators.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/app_text_field.dart';
import 'package:lean_assistant/core/widgets/primary_button.dart';
import 'package:lean_assistant/features/auth/domain/password_rules.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';
import 'package:lean_assistant/features/auth/presentation/change_password_cubit.dart';

/// Shown to a user whose password was set by an admin.
/// The router keeps the user here until the password is changed.
class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChangePasswordCubit>(
      create: (_) => getIt<ChangePasswordCubit>(),
      child: const _ChangePasswordForm(),
    );
  }
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm();

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  /// The server's name for the field, in its validation errors.
  static const String _currentPasswordField = 'CurrentPassword';

  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<ChangePasswordCubit>().submit(
      currentPassword: _current.text,
      newPassword: _new.text,
    );
  }

  String? _validateNew(String? value, AppLocalizations l10n) {
    final password = value ?? '';

    if (password.isEmpty) return l10n.fieldRequired;
    if (password.length < PasswordRules.minimumLength) {
      return l10n.changePasswordTooShort(PasswordRules.minimumLength);
    }
    if (password == _current.text) return l10n.changePasswordSameAsCurrent;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.changePasswordTitle),
        actions: [
          TextButton(
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthSignOutRequested()),
            child: Text(l10n.homeSignOut),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: BlocBuilder<ChangePasswordCubit, SubmitState>(
                builder: (context, state) {
                  // "Wrong current password" belongs under that field;
                  // any other failure is shown above the button.
                  final currentPasswordError = switch (state) {
                    SubmitFailed(failure: ValidationFailure(:final fieldErrors))
                        when fieldErrors.containsKey(_currentPasswordField) =>
                      l10n.changePasswordWrongCurrent,
                    _ => null,
                  };
                  final generalError = switch (state) {
                    SubmitFailed(:final failure)
                        when currentPasswordError == null =>
                      failure.message(l10n),
                    _ => null,
                  };

                  return Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.changePasswordRequiredInfo),
                          const SizedBox(height: 24),
                          AppTextField(
                            label: l10n.changePasswordCurrent,
                            controller: _current,
                            obscureText: true,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.next,
                            errorText: currentPasswordError,
                            validator: Validators.required(l10n),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: l10n.changePasswordNew,
                            controller: _new,
                            obscureText: true,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.next,
                            validator: (value) => _validateNew(value, l10n),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: l10n.changePasswordConfirm,
                            controller: _confirm,
                            obscureText: true,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) => value == _new.text
                                ? null
                                : l10n.changePasswordMismatch,
                          ),
                          if (generalError != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              generalError,
                              style: TextStyle(color: theme.colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: l10n.changePasswordSubmit,
                            isLoading: state is SubmitInProgress,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
