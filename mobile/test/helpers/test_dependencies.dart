import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/features/auth/domain/auth_repository.dart';
import 'package:lean_assistant/features/auth/presentation/change_password_cubit.dart';
import 'package:lean_assistant/features/auth/presentation/login_cubit.dart';
import 'package:lean_assistant/features/dashboard/domain/health_repository.dart';
import 'package:lean_assistant/features/dashboard/domain/server_health.dart';
import 'package:lean_assistant/features/dashboard/presentation/server_status_cubit.dart';

import 'fake_auth.dart';

/// Health repository that always answers "healthy", without any network.
class FakeHealthRepository implements HealthRepository {
  @override
  Future<Result<ServerHealth>> check() async => const Ok(ServerHealth.healthy);
}

/// Pages under test only render; any real sign-in call would be a mistake.
class _UnusedAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Not expected in this test.');
}

/// Registers fakes for everything pages read from getIt.
/// Use in `setUp` together with `tearDown(getIt.reset)`.
void registerTestDependencies() {
  getIt
    ..registerFactory<ServerStatusCubit>(
      () => ServerStatusCubit(FakeHealthRepository()),
    )
    ..registerFactory<LoginCubit>(
      () => LoginCubit(_UnusedAuthRepository(), MockAuthBloc()),
    )
    ..registerFactory<ChangePasswordCubit>(
      () => ChangePasswordCubit(_UnusedAuthRepository(), MockAuthBloc()),
    );
}
