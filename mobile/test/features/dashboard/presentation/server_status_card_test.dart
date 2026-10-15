import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/features/dashboard/domain/server_health.dart';
import 'package:lean_assistant/features/dashboard/presentation/server_status_card.dart';
import 'package:lean_assistant/features/dashboard/presentation/server_status_cubit.dart';
import 'package:lean_assistant/features/dashboard/presentation/server_status_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockServerStatusCubit extends MockCubit<ServerStatusState>
    implements ServerStatusCubit {}

void main() {
  late _MockServerStatusCubit cubit;

  setUp(() => cubit = _MockServerStatusCubit());

  Future<void> pumpCard(WidgetTester tester) {
    return tester.pumpApp(
      BlocProvider<ServerStatusCubit>.value(
        value: cubit,
        child: const ServerStatusCard(),
      ),
    );
  }

  testWidgets('shows connected when the server is online', (tester) async {
    when(() => cubit.state)
        .thenReturn(const ServerStatusOnline(ServerHealth.healthy));

    await pumpCard(tester);

    expect(find.text('Bağlı'), findsOneWidget);
  });

  testWidgets('shows the failure message and checks again on tap', (
    tester,
  ) async {
    when(() => cubit.state)
        .thenReturn(const ServerStatusOffline(NetworkFailure()));
    when(() => cubit.check()).thenAnswer((_) async {});

    await pumpCard(tester);
    expect(
      find.text('Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edin.'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.refresh));
    verify(() => cubit.check()).called(1);
  });
}
