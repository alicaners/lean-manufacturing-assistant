import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/features/dashboard/domain/health_repository.dart';
import 'package:lean_assistant/features/dashboard/domain/server_health.dart';
import 'package:lean_assistant/features/dashboard/presentation/server_status_cubit.dart';

/// Health repository that always answers "healthy", without any network.
class FakeHealthRepository implements HealthRepository {
  @override
  Future<Result<ServerHealth>> check() async => const Ok(ServerHealth.healthy);
}

/// Registers fakes for everything pages read from getIt.
/// Use in `setUp` together with `tearDown(getIt.reset)`.
void registerTestDependencies() {
  getIt.registerFactory<ServerStatusCubit>(
    () => ServerStatusCubit(FakeHealthRepository()),
  );
}
