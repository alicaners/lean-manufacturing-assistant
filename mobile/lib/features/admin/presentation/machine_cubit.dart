import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/organization_repository.dart';
import 'package:lean_assistant/features/admin/presentation/machine_state.dart';

/// Loads one machine and replaces its QR code on request.
@injectable
class MachineCubit extends Cubit<MachineState> {
  MachineCubit(this._organization) : super(const MachineState());

  final OrganizationRepository _organization;

  Future<void> load(String id) async {
    // The first load starts in "loading" already; a retry goes back to it.
    if (state.status != MachineStatus.loading) emit(const MachineState());

    final result = await _organization.machine(id);
    if (isClosed) return;

    emit(switch (result) {
      Ok(:final value) => MachineState(
        status: MachineStatus.ready,
        machine: value,
      ),
      Err(:final failure) => MachineState(
        status: MachineStatus.failed,
        failure: failure,
      ),
    });
  }

  Future<void> regenerateQr() async {
    final machine = state.machine;
    if (machine == null || state.regenerate is SubmitInProgress) return;

    emit(
      MachineState(
        status: MachineStatus.ready,
        machine: machine,
        regenerate: const SubmitInProgress(),
      ),
    );

    final result = await _organization.regenerateQr(machine.id);
    if (isClosed) return;

    emit(switch (result) {
      // The server answers with the machine and its new code.
      Ok(:final value) => MachineState(
        status: MachineStatus.ready,
        machine: value,
        regenerate: const SubmitSucceeded(),
      ),
      Err(:final failure) => MachineState(
        status: MachineStatus.ready,
        machine: machine,
        regenerate: SubmitFailed(failure),
      ),
    });
  }
}
