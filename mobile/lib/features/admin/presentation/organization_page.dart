import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/router/app_router.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/failure_message.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/core/forms/validators.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/app_text_field.dart';
import 'package:lean_assistant/core/widgets/empty_view.dart';
import 'package:lean_assistant/core/widgets/error_view.dart';
import 'package:lean_assistant/core/widgets/loading_view.dart';
import 'package:lean_assistant/features/admin/domain/plant_tree.dart';
import 'package:lean_assistant/features/admin/presentation/organization_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/organization_state.dart';

/// What the add/rename dialog returns: a name, and a code for a new machine.
typedef _NameAnswer = ({String name, String? code});

/// A plant's departments, lines and machines, with the admin's changes.
class OrganizationPage extends StatelessWidget {
  const OrganizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrganizationCubit>(
      create: (_) => getIt<OrganizationCubit>()..load(),
      child: const _OrganizationView(),
    );
  }
}

class _OrganizationView extends StatelessWidget {
  const _OrganizationView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<OrganizationCubit>();

    return BlocConsumer<OrganizationCubit, OrganizationState>(
      listenWhen: (previous, current) => previous.change != current.change,
      listener: (context, state) {
        final message = switch (state.change) {
          SubmitSucceeded() => l10n.organizationSaved,
          SubmitFailed(failure: ConflictFailure()) => l10n.organizationConflict,
          SubmitFailed(:final failure) => failure.message(l10n),
          _ => null,
        };
        if (message != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final tree = state.tree;
        final ready = state.status == OrganizationStatus.ready;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.organizationTitle)),
          floatingActionButton: ready && tree != null
              ? FloatingActionButton.extended(
                  onPressed: () => _addDepartment(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.organizationAddDepartment),
                )
              : null,
          body: switch (state.status) {
            OrganizationStatus.failed => ErrorView(
              message: state.failure?.message(l10n),
              onRetry: cubit.load,
            ),
            OrganizationStatus.ready when state.plants.isEmpty => EmptyView(
              message: l10n.organizationNoPlants,
              icon: Icons.factory_outlined,
            ),
            OrganizationStatus.ready when tree != null => Column(
              children: [
                if (state.plants.length > 1) _PlantPicker(state: state),
                if (state.change is SubmitInProgress)
                  const LinearProgressIndicator(),
                Expanded(child: _Tree(tree: tree)),
              ],
            ),
            _ => const LoadingView(),
          },
        );
      },
    );
  }
}

/// Only shown to a system admin who manages more than one plant.
class _PlantPicker extends StatelessWidget {
  const _PlantPicker({required this.state});

  final OrganizationState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DropdownButton<String>(
        value: state.plantId,
        isExpanded: true,
        items: [
          for (final plant in state.plants)
            DropdownMenuItem(
              value: plant.id,
              child: Text('${plant.name} (${plant.code})'),
            ),
        ],
        onChanged: (plantId) {
          if (plantId != null) {
            context.read<OrganizationCubit>().selectPlant(plantId);
          }
        },
      ),
    );
  }
}

class _Tree extends StatelessWidget {
  const _Tree({required this.tree});

  final PlantTree tree;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (tree.departments.isEmpty) {
      return EmptyView(
        message: l10n.organizationNoDepartments,
        icon: Icons.account_tree_outlined,
      );
    }

    return ListView(
      // Room for the "Add department" button over the last row.
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        for (final department in tree.departments)
          ExpansionTile(
            // Remembers which departments were open when the tree reloads.
            key: PageStorageKey(department.id),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(department.name),
            subtitle: Text(l10n.organizationLineCount(department.lines.length)),
            trailing: _NodeMenu(
              addLabel: l10n.organizationAddLine,
              onAdd: () => _addLine(context, department),
              onRename: () => _rename(
                context,
                TreeNodeKind.department,
                department.id,
                department.name,
              ),
            ),
            children: [
              if (department.lines.isEmpty)
                _EmptyRow(l10n.organizationNoLines, indent: 32),
              for (final line in department.lines) _LineTile(line: line),
            ],
          ),
      ],
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line});

  final LineNode line;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ExpansionTile(
      key: PageStorageKey(line.id),
      tilePadding: const EdgeInsets.only(left: 32, right: 16),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(line.name),
      subtitle: Text(l10n.organizationMachineCount(line.machines.length)),
      trailing: _NodeMenu(
        addLabel: l10n.organizationAddMachine,
        onAdd: () => _addMachine(context, line),
        onRename: () => _rename(context, TreeNodeKind.line, line.id, line.name),
      ),
      children: [
        if (line.machines.isEmpty)
          _EmptyRow(l10n.organizationNoMachines, indent: 72),
        for (final machine in line.machines)
          ListTile(
            onTap: () => context.push(AppRoutes.machineOf(machine.id)),
            contentPadding: const EdgeInsets.only(left: 72, right: 16),
            leading: const Icon(Icons.precision_manufacturing_outlined),
            title: Text(machine.name),
            subtitle: Text(machine.code),
            trailing: _NodeMenu(
              onRename: () => _rename(
                context,
                TreeNodeKind.machine,
                machine.id,
                machine.name,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow(this.message, {required this.indent});

  final String message;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: indent, right: 16),
      title: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

/// The ⋮ menu of a row: "add" (departments and lines only) and "rename".
class _NodeMenu extends StatelessWidget {
  const _NodeMenu({required this.onRename, this.addLabel, this.onAdd});

  final VoidCallback onRename;
  final String? addLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = addLabel;
    final add = onAdd;

    return PopupMenuButton<VoidCallback>(
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        if (label != null && add != null)
          PopupMenuItem(value: add, child: Text(label)),
        PopupMenuItem(value: onRename, child: Text(l10n.organizationRename)),
      ],
    );
  }
}

Future<void> _addDepartment(BuildContext context) async {
  final cubit = context.read<OrganizationCubit>();
  final answer = await _askName(
    context,
    title: context.l10n.organizationAddDepartment,
  );
  if (answer != null) await cubit.addDepartment(answer.name);
}

Future<void> _addLine(BuildContext context, DepartmentNode department) async {
  final cubit = context.read<OrganizationCubit>();
  final answer = await _askName(
    context,
    title: context.l10n.organizationAddLine,
  );
  if (answer != null) await cubit.addLine(department.id, answer.name);
}

Future<void> _addMachine(BuildContext context, LineNode line) async {
  final cubit = context.read<OrganizationCubit>();
  final answer = await _askName(
    context,
    title: context.l10n.organizationAddMachine,
    askCode: true,
  );
  final code = answer?.code;
  if (answer != null && code != null) {
    await cubit.addMachine(line.id, name: answer.name, code: code);
  }
}

Future<void> _rename(
  BuildContext context,
  TreeNodeKind kind,
  String id,
  String currentName,
) async {
  final cubit = context.read<OrganizationCubit>();
  final answer = await _askName(
    context,
    title: context.l10n.organizationRename,
    initialName: currentName,
  );
  if (answer != null && answer.name != currentName) {
    await cubit.rename(kind, id, answer.name);
  }
}

Future<_NameAnswer?> _askName(
  BuildContext context, {
  required String title,
  String initialName = '',
  bool askCode = false,
}) {
  return showDialog<_NameAnswer>(
    context: context,
    builder: (_) =>
        _NameDialog(title: title, initialName: initialName, askCode: askCode),
  );
}

/// Asks for a name (and a code for a new machine); closes with them, or null.
class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.initialName,
    required this.askCode,
  });

  final String title;
  final String initialName;
  final bool askCode;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  /// The characters the backend accepts in a machine code.
  static final RegExp _codePattern = RegExp(r'^[A-Za-z0-9-]+$');

  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  final _code = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop<_NameAnswer>((
      name: _name.text.trim(),
      code: widget.askCode ? _code.text.trim().toUpperCase() : null,
    ));
  }

  String? _validateCode(String? value, AppLocalizations l10n) {
    final code = value?.trim() ?? '';

    if (code.isEmpty) return l10n.fieldRequired;
    if (!_codePattern.hasMatch(code)) return l10n.organizationCodeInvalid;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: l10n.organizationName,
              controller: _name,
              textInputAction: widget.askCode
                  ? TextInputAction.next
                  : TextInputAction.done,
              onFieldSubmitted: widget.askCode ? null : (_) => _submit(),
              validator: Validators.required(l10n),
            ),
            if (widget.askCode) ...[
              const SizedBox(height: 16),
              AppTextField(
                label: l10n.organizationMachineCode,
                controller: _code,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) => _validateCode(value, l10n),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.editAccessSave)),
      ],
    );
  }
}
