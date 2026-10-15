import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/features/dashboard/domain/health_repository.dart';
import 'package:lean_assistant/features/dashboard/domain/server_health.dart';
import 'package:lean_assistant/features/dashboard/presentation/server_status_cubit.dart';
import 'package:lean_assistant/features/dashboard/presentation/server_status_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockHealthRepository extends Mock implements HealthRepository {}

void main() {
  late _MockHealthRepository repository;

  setUp(() => repository = _MockHealthRepository());

  blocTest<ServerStatusCubit, ServerStatusState>(
    'emits Loading then Online when the server answers',
    setUp: () =>
        when(() => repository.check())
            .thenAnswer((_) async => const Ok(ServerHealth.healthy)),
    build: () => ServerStatusCubit(repository),
    act: (cubit) => cubit.check(),
    expect: () => [
      isA<ServerStatusLoading>(),
      isA<ServerStatusOnline>().having(
        (state) => state.health,
        'health',
        ServerHealth.healthy,
      ),
    ],
  );

  blocTest<ServerStatusCubit, ServerStatusState>(
    'emits Loading then Offline with the failure when the server is unreachable',
    setUp: () =>
        when(() => repository.check())
            .thenAnswer((_) async => const Err(NetworkFailure())),
    build: () => ServerStatusCubit(repository),
    act: (cubit) => cubit.check(),
    expect: () => [
      isA<ServerStatusLoading>(),
      isA<ServerStatusOffline>().having(
        (state) => state.failure,
        'failure',
        isA<NetworkFailure>(),
      ),
    ],
  );

  blocTest<ServerStatusCubit, ServerStatusState>(
    'shows loading again when retrying after a failure',
    setUp: () =>
        when(() => repository.check())
            .thenAnswer((_) async => const Ok(ServerHealth.healthy)),
    build: () => ServerStatusCubit(repository),
    seed: () => const ServerStatusOffline(NetworkFailure()),
    act: (cubit) => cubit.check(),
    expect: () => [isA<ServerStatusLoading>(), isA<ServerStatusOnline>()],
  );
}
