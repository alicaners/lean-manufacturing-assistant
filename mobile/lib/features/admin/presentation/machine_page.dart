import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/core/error/failure_message.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/error_view.dart';
import 'package:lean_assistant/core/widgets/loading_view.dart';
import 'package:lean_assistant/core/widgets/primary_button.dart';
import 'package:lean_assistant/features/admin/domain/machine_detail.dart';
import 'package:lean_assistant/features/admin/domain/machine_qr.dart';
import 'package:lean_assistant/features/admin/presentation/machine_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/machine_label.dart';
import 'package:lean_assistant/features/admin/presentation/machine_state.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// One machine: its QR label, sharing it, and replacing a lost label.
class MachinePage extends StatelessWidget {
  const MachinePage({super.key, required this.machineId});

  final String machineId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MachineCubit>(
      create: (_) => getIt<MachineCubit>()..load(machineId),
      child: _MachineView(machineId: machineId),
    );
  }
}

class _MachineView extends StatelessWidget {
  const _MachineView({required this.machineId});

  final String machineId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<MachineCubit>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.machineTitle)),
      body: BlocConsumer<MachineCubit, MachineState>(
        listenWhen: (previous, current) =>
            previous.regenerate != current.regenerate,
        listener: (context, state) {
          final message = switch (state.regenerate) {
            SubmitSucceeded() => l10n.machineRegenerated,
            SubmitFailed(:final failure) => failure.message(l10n),
            _ => null,
          };
          if (message != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          if (state.status == MachineStatus.failed) {
            return ErrorView(
              message: state.failure?.message(l10n),
              onRetry: () => cubit.load(machineId),
            );
          }

          final machine = state.machine;
          if (machine == null) return const LoadingView();

          return _MachineDetails(
            machine: machine,
            busy: state.regenerate is SubmitInProgress,
          );
        },
      ),
    );
  }
}

class _MachineDetails extends StatefulWidget {
  const _MachineDetails({required this.machine, required this.busy});

  final MachineDetail machine;

  /// A new QR code is being made.
  final bool busy;

  @override
  State<_MachineDetails> createState() => _MachineDetailsState();
}

class _MachineDetailsState extends State<_MachineDetails> {
  /// The label is being drawn or the share sheet is open.
  bool _sharing = false;

  Future<void> _share() async {
    // Read everything that needs the context before waiting.
    final messenger = ScaffoldMessenger.of(context);
    final failedMessage = context.l10n.machineShareFailed;
    final machine = widget.machine;

    setState(() => _sharing = true);
    try {
      final png = await renderMachineLabel(
        payload: MachineQr.payloadOf(machine.qrCode),
        name: machine.name,
        code: machine.code,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              png,
              mimeType: 'image/png',
              name: 'qr-${machine.code}.png',
            ),
          ],
          text: '${machine.name} (${machine.code})',
        ),
      );
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _confirmRegenerate() async {
    final cubit = context.read<MachineCubit>();
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.machineRegenerateTitle),
        content: Text(l10n.machineRegenerateMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.machineRegenerate),
          ),
        ],
      ),
    );

    if (confirmed == true) await cubit.regenerateQr();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final machine = widget.machine;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (widget.busy) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
        ],
        Text(
          machine.name,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        Text(machine.code, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Center(
          // Scanners need dark squares on a light background, also in dark mode.
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: MachineQr.payloadOf(machine.qrCode),
              size: 240,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.machineLabelInfo,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: l10n.machineShareLabel,
          isLoading: _sharing,
          onPressed: _share,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: widget.busy ? null : _confirmRegenerate,
          icon: const Icon(Icons.autorenew),
          label: Text(l10n.machineRegenerate),
        ),
      ],
    );
  }
}
