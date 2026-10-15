import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/features/dashboard/domain/server_health.dart';

/// Asks the backend whether it is up.
abstract interface class HealthRepository {
  Future<Result<ServerHealth>> check();
}
