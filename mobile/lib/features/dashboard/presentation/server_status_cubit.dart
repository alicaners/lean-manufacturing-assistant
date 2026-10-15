import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/features/dashboard/domain/health_repository.dart';
import 'package:lean_assistant/features/dashboard/presentation/server_status_state.dart';

/// Checks the backend's health and exposes the result as [ServerStatusState].
@injectable
class ServerStatusCubit extends Cubit<ServerStatusState> {
  ServerStatusCubit(this._repository) : super(const ServerStatusLoading());

  final HealthRepository _repository;

  Future<void> check() async {
    emit(const ServerStatusLoading());

    final result = await _repository.check();

    // The page may have been closed while we were waiting.
    if (isClosed) return;

    emit(switch (result) {
      Ok(:final value) => ServerStatusOnline(value),
      Err(:final failure) => ServerStatusOffline(failure),
    });
  }
}
