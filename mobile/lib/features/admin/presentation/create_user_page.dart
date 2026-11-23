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
import 'package:lean_assistant/core/widgets/error_view.dart';
import 'package:lean_assistant/core/widgets/loading_view.dart';
import 'package:lean_assistant/core/widgets/primary_button.dart';
import 'package:lean_assistant/features/admin/domain/new_user.dart';
import 'package:lean_assistant/features/admin/presentation/create_user_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/create_user_state.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';
import 'package:lean_assistant/features/auth/domain/password_rules.dart';
import 'package:lean_assistant/features/auth/presentation/user_role_label.dart';

/// Form for creating a user. Closes itself with `true` once the user exists.
class CreateUserPage extends StatelessWidget {
  const CreateUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateUserCubit>(
      create: (_) => getIt<CreateUserCubit>()..loadPlants(),
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

  UserRole _role = UserRole.operator;
  String? _plantId;
  String? _lineId;

  @override
  void dispose() {
    _userName.dispose();
    _fullName.dispose();
    _password.dispose();
    super.dispose();
  }

  void _selectPlant(String? plantId) {
    setState(() {
      _plantId = plantId;
      _lineId = null;
    });
    context.read<CreateUserCubit>().plantChanged(plantId);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<CreateUserCubit>().submit(
      NewUser(
        userName: _userName.text.trim(),
        fullName: _fullName.text.trim(),
        temporaryPassword: _password.text,
        role: _role,
        plantId: _plantId,
        lineId: _role.worksOnLine ? _lineId : null,
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

  String? _validatePassword(String? value, AppLocalizations l10n) {
    final password = value ?? '';

    if (password.isEmpty) return l10n.fieldRequired;
    if (password.length < PasswordRules.minimumLength) {
      return l10n.changePasswordTooShort(PasswordRules.minimumLength);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.usersNew)),
      body: MultiBlocListener(
        listeners: [
          // With a single plant there is nothing to choose: pick it.
          BlocListener<CreateUserCubit, CreateUserState>(
            listenWhen: (previous, current) =>
                previous.plantsStatus != current.plantsStatus &&
                current.plantsStatus == OptionsStatus.ready,
            listener: (context, state) {
              if (state.plants.length == 1) {
                _selectPlant(state.plants.single.id);
              }
            },
          ),
          // Created: close the form and tell the list.
          BlocListener<CreateUserCubit, CreateUserState>(
            listenWhen: (previous, current) =>
                previous.submit != current.submit &&
                current.submit is SubmitSucceeded,
            listener: (context, state) => context.pop(true),
          ),
        ],
        child: BlocBuilder<CreateUserCubit, CreateUserState>(
          builder: (context, state) => switch (state.plantsStatus) {
            OptionsStatus.failed => ErrorView(
              message: state.loadFailure?.message(l10n),
              onRetry: context.read<CreateUserCubit>().loadPlants,
            ),
            OptionsStatus.ready => _buildForm(context, state),
            _ => const LoadingView(),
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, CreateUserState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final submit = state.submit;

    // "User name taken" belongs under that field; other failures above the button.
    final userNameTaken =
        submit is SubmitFailed && submit.failure is ConflictFailure;
    final generalError = switch (submit) {
      SubmitFailed(failure: ConflictFailure()) => null,
      SubmitFailed(failure: ForbiddenFailure()) => l10n.userFormOutsideScope,
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
              errorText: userNameTaken ? l10n.userFormUserNameTaken : null,
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
              validator: (value) => _validatePassword(value, l10n),
            ),
            const SizedBox(height: 8),
            Text(l10n.userFormPasswordInfo, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.userFormRole),
              items: [
                for (final role in UserRole.values)
                  DropdownMenuItem(value: role, child: Text(role.label(l10n))),
              ],
              onChanged: (role) {
                if (role != null) setState(() => _role = role);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _plantId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.userFormPlant),
              items: [
                // "No plant" is only possible for an admin.
                if (!_role.needsPlant)
                  DropdownMenuItem(child: Text(l10n.userFormAllPlants)),
                for (final plant in state.plants)
                  DropdownMenuItem(
                    value: plant.id,
                    child: Text('${plant.name} (${plant.code})'),
                  ),
              ],
              validator: (value) =>
                  value == null && _role.needsPlant ? l10n.fieldRequired : null,
              onChanged: _selectPlant,
            ),
            if (_role.worksOnLine && _plantId != null) ...[
              const SizedBox(height: 16),
              _buildLineField(context, state),
            ],
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
  }

  Widget _buildLineField(BuildContext context, CreateUserState state) {
    final l10n = context.l10n;

    if (state.linesStatus == OptionsStatus.failed) {
      return Row(
        children: [
          Expanded(
            child: Text(
              l10n.userFormLinesFailed,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextButton(
            onPressed: () => _selectPlant(_plantId),
            child: Text(l10n.commonRetry),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      // A new plant or a finished load starts the field afresh.
      key: ValueKey('lines-$_plantId-${state.linesStatus}'),
      initialValue: _lineId,
      isExpanded: true,
      decoration: InputDecoration(labelText: l10n.userFormLine),
      hint: state.linesStatus == OptionsStatus.loading
          ? Text(l10n.commonLoading)
          : null,
      items: [
        for (final line in state.lines)
          DropdownMenuItem(
            value: line.id,
            child: Text('${line.departmentName} · ${line.name}'),
          ),
      ],
      validator: (value) => value == null ? l10n.fieldRequired : null,
      onChanged: (lineId) => setState(() => _lineId = lineId),
    );
  }
}
