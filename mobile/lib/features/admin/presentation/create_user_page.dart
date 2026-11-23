import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/failure_message.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/core/forms/validators.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/app_text_field.dart';
import 'package:lean_assistant/core/widgets/primary_button.dart';
import 'package:lean_assistant/features/admin/domain/new_user.dart';
import 'package:lean_assistant/features/admin/domain/user_access.dart';
import 'package:lean_assistant/features/admin/presentation/access_fields.dart';
import 'package:lean_assistant/features/admin/presentation/access_options_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/create_user_cubit.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';
import 'package:lean_assistant/features/auth/domain/password_rules.dart';

/// Form for creating a user. Closes itself with `true` once the user exists.
class CreateUserPage extends StatelessWidget {
  const CreateUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AccessOptionsCubit>(
          create: (_) => getIt<AccessOptionsCubit>()..loadPlants(),
        ),
        BlocProvider<CreateUserCubit>(create: (_) => getIt<CreateUserCubit>()),
      ],
      child: const _CreateUserForm(),
    );
  }
}

class _CreateUserForm extends StatefulWidget {
  const _CreateUserForm();

  @override
  State<_CreateUserForm> createState() => _CreateUserFormState();
}

class _CreateUserFormState extends State<_CreateUserForm> {
  /// The characters the backend accepts in a user name.
  static final RegExp _userNamePattern = RegExp(r'^[a-zA-Z0-9._-]+$');

  final _formKey = GlobalKey<FormState>();
  final _userName = TextEditingController();
  final _fullName = TextEditingController();
  final _password = TextEditingController();

  UserAccess _access = const UserAccess(role: UserRole.operator);

  @override
  void dispose() {
    _userName.dispose();
    _fullName.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<CreateUserCubit>().submit(
      NewUser(
        userName: _userName.text.trim(),
        fullName: _fullName.text.trim(),
        temporaryPassword: _password.text,
        role: _access.role,
        plantId: _access.plantId,
        lineId: _access.lineId,
      ),
    );
  }

  String? _validateUserName(String? value, AppLocalizations l10n) {
    final userName = value?.trim() ?? '';

    if (userName.isEmpty) return l10n.fieldRequired;
    if (!_userNamePattern.hasMatch(userName)) {
      return l10n.userFormUserNameInvalid;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.usersNew)),
      body: BlocConsumer<CreateUserCubit, SubmitState>(
        // Created: close the form and tell the list.
        listener: (context, submit) {
          if (submit is SubmitSucceeded) context.pop(true);
        },
        builder: (context, submit) {
          // "User name taken" belongs under that field; others above the button.
          final userNameTaken =
              submit is SubmitFailed && submit.failure is ConflictFailure;
          final generalError = switch (submit) {
            SubmitFailed(failure: ConflictFailure()) => null,
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
                  AppTextField(
                    label: l10n.loginUserName,
                    controller: _userName,
                    textInputAction: TextInputAction.next,
                    errorText: userNameTaken
                        ? l10n.userFormUserNameTaken
                        : null,
                    validator: (value) => _validateUserName(value, l10n),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: l10n.userFormFullName,
                    controller: _fullName,
                    textInputAction: TextInputAction.next,
                    validator: Validators.required(l10n),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: l10n.userFormTemporaryPassword,
                    controller: _password,
                    validator: Validators.password(
                      l10n,
                      minLength: PasswordRules.minimumLength,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.userFormPasswordInfo,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  AccessFields(
                    initial: _access,
                    onChanged: (access) => _access = access,
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
                    label: l10n.userFormSubmit,
                    isLoading: submit is SubmitInProgress,
                    onPressed: _submit,
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
