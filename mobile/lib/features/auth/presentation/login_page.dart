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
import 'package:lean_assistant/features/auth/presentation/login_cubit.dart';

/// Sign-in form.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginCubit>(
      create: (_) => getIt<LoginCubit>(),
      child: const _LoginForm(),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _userName = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _userName.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<LoginCubit>().submit(
      userName: _userName.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: BlocBuilder<LoginCubit, SubmitState>(
                builder: (context, state) => Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.precision_manufacturing_outlined,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.appTitle,
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.loginSubtitle, textAlign: TextAlign.center),
                        const SizedBox(height: 32),
                        AppTextField(
                          label: l10n.loginUserName,
                          controller: _userName,
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          validator: Validators.required(l10n),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: l10n.loginPassword,
                          controller: _password,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: Validators.required(l10n),
                        ),
                        if (state case SubmitFailed(:final failure)) ...[
                          const SizedBox(height: 16),
                          Text(
                            _messageFor(failure, l10n),
                            style: TextStyle(color: theme.colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: l10n.loginSubmit,
                          isLoading: state is SubmitInProgress,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// On the sign-in page a 401 means wrong credentials, not an expired session.
  static String _messageFor(Failure failure, AppLocalizations l10n) {
    return switch (failure) {
      UnauthorizedFailure() => l10n.loginInvalidCredentials,
      _ => failure.message(l10n),
    };
  }
}
