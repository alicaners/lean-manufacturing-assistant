import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/features/admin/domain/user_access.dart';
import 'package:lean_assistant/features/admin/presentation/access_options_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/access_options_state.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';
import 'package:lean_assistant/features/auth/presentation/user_role_label.dart';

/// Role, plant and line fields with the rules of docs/business-rules.md.
/// Reads the choices from [AccessOptionsCubit]; must be inside a [Form],
/// whose `validate()` checks these fields too.
class AccessFields extends StatefulWidget {
  const AccessFields({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  /// Where the fields start: a default for a new user, the current access
  /// when editing.
  final UserAccess initial;

  final ValueChanged<UserAccess> onChanged;

  @override
  State<AccessFields> createState() => _AccessFieldsState();
}

class _AccessFieldsState extends State<AccessFields> {
  late UserAccess _access = widget.initial;

  @override
  void initState() {
    super.initState();
    // When editing, the plant is chosen already: load its lines.
    if (widget.initial.plantId case final plantId?) {
      context.read<AccessOptionsCubit>().plantChanged(plantId);
    }
  }

  void _update(UserAccess access) {
    setState(() => _access = access);
    widget.onChanged(access);
  }

  void _selectPlant(String? plantId) {
    _update(_access.withPlant(plantId));
    context.read<AccessOptionsCubit>().plantChanged(plantId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<AccessOptionsCubit, AccessOptionsState>(
      // With a single plant there is nothing to choose: pick it.
      listenWhen: (previous, current) =>
          previous.plantsStatus != current.plantsStatus &&
          current.plantsStatus == OptionsStatus.ready,
      listener: (context, state) {
        if (state.plants.length == 1 &&
            _access.plantId == null &&
            _access.role.needsPlant) {
          _selectPlant(state.plants.single.id);
        }
      },
      builder: (context, state) => switch (state.plantsStatus) {
        OptionsStatus.ready => _buildFields(context, state),
        OptionsStatus.failed => _RetryRow(
          message: l10n.userFormPlantsFailed,
          onRetry: context.read<AccessOptionsCubit>().loadPlants,
        ),
        _ => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      },
    );
  }

  Widget _buildFields(BuildContext context, AccessOptionsState state) {
    final l10n = context.l10n;
    final plantId = _access.plantId;
    // Only start from a value the list really has; a dropdown rejects others.
    final knownPlant = state.plants.any((plant) => plant.id == plantId)
        ? plantId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<UserRole>(
          initialValue: _access.role,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.userFormRole),
          items: [
            for (final role in UserRole.values)
              DropdownMenuItem(value: role, child: Text(role.label(l10n))),
          ],
          onChanged: (role) {
            if (role != null) _update(_access.withRole(role));
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: knownPlant,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.userFormPlant),
          items: [
            // "No plant" is only possible for an admin.
            if (!_access.role.needsPlant)
              DropdownMenuItem(child: Text(l10n.userFormAllPlants)),
            for (final plant in state.plants)
              DropdownMenuItem(
                value: plant.id,
                child: Text('${plant.name} (${plant.code})'),
              ),
          ],
          validator: (value) => value == null && _access.role.needsPlant
              ? l10n.fieldRequired
              : null,
          onChanged: _selectPlant,
        ),
        if (_access.role.worksOnLine && plantId != null) ...[
          const SizedBox(height: 16),
          _buildLineField(context, state),
        ],
      ],
    );
  }

  Widget _buildLineField(BuildContext context, AccessOptionsState state) {
    final l10n = context.l10n;

    if (state.linesStatus == OptionsStatus.failed) {
      return _RetryRow(
        message: l10n.userFormLinesFailed,
        onRetry: () =>
            context.read<AccessOptionsCubit>().plantChanged(_access.plantId),
      );
    }

    final lineId = _access.lineId;
    final knownLine = state.lines.any((line) => line.id == lineId)
        ? lineId
        : null;

    return DropdownButtonFormField<String>(
      // A new plant or a finished load starts the field afresh.
      key: ValueKey('lines-${_access.plantId}-${state.linesStatus}'),
      initialValue: knownLine,
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
      onChanged: (lineId) => _update(_access.withLine(lineId)),
    );
  }
}

/// An error message with a retry button, in place of a field.
class _RetryRow extends StatelessWidget {
  const _RetryRow({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
      ],
    );
  }
}
