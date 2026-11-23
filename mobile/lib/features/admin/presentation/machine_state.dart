import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/machine_detail.dart';

enum MachineStatus { loading, ready, failed }

class MachineState {
  const MachineState({
    this.status = MachineStatus.loading,
    this.machine,
    this.failure,
    this.regenerate = const SubmitIdle(),
  });

  final MachineStatus status;
  final MachineDetail? machine;

  /// Why the machine could not be loaded.
  final Failure? failure;

  /// The state of making a new QR code.
  final SubmitState regenerate;
}
