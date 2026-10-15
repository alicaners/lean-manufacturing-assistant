import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/features/dashboard/domain/server_health.dart';

/// What the server status card shows.
sealed class ServerStatusState {
  const ServerStatusState();
}

/// The request is in flight.
final class ServerStatusLoading extends ServerStatusState {
  const ServerStatusLoading();
}

/// The server answered.
final class ServerStatusOnline extends ServerStatusState {
  const ServerStatusOnline(this.health);

  final ServerHealth health;
}

/// The server could not be reached or answered with an error.
final class ServerStatusOffline extends ServerStatusState {
  const ServerStatusOffline(this.failure);

  final Failure failure;
}
