import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/features/admin/presentation/user_list_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/user_list_state.dart';
import 'package:lean_assistant/features/admin/presentation/users_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_users.dart';
import '../../../helpers/pump_app.dart';

class _MockUserListCubit extends MockCubit<UserListState>
    implements UserListCubit {}

void main() {
  late _MockUserListCubit cubit;

  setUp(() {
    cubit = _MockUserListCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    getIt.registerFactory<UserListCubit>(() => cubit);
  });

  tearDown(getIt.reset);

  testWidgets('shows each user with their role', (tester) async {
    when(() => cubit.state).thenReturn(
      const UserListState(status: UserListStatus.ready, users: [operatorUser]),
    );

    await tester.pumpApp(const UsersPage());

    expect(find.text('Demo Operatör'), findsOneWidget);
    expect(find.text('demo.operator · Operatör'), findsOneWidget);
  });

  testWidgets('says so when no user matches', (tester) async {
    when(() => cubit.state)
        .thenReturn(const UserListState(status: UserListStatus.ready));

    await tester.pumpApp(const UsersPage());

    expect(find.text('Bu filtrelere uyan kullanıcı yok.'), findsOneWidget);
  });
}
