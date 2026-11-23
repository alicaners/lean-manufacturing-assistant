import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/features/admin/domain/managed_user.dart';
import 'package:lean_assistant/features/admin/presentation/user_detail_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/user_detail_page.dart';
import 'package:lean_assistant/features/admin/presentation/user_detail_state.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_auth.dart';
import '../../../helpers/fake_users.dart';
import '../../../helpers/pump_app.dart';

class _MockUserDetailCubit extends MockCubit<UserDetailState>
    implements UserDetailCubit {}

void main() {
  late _MockUserDetailCubit cubit;

  setUp(() {
    cubit = _MockUserDetailCubit();
    when(() => cubit.load(any())).thenAnswer((_) async {});
    getIt.registerFactory<UserDetailCubit>(() => cubit);
  });

  tearDown(getIt.reset);

  /// Opens the page of [user] while [testAdmin] is signed in.
  Future<void> openPageOf(WidgetTester tester, ManagedUser user) async {
    when(
      () => cubit.state,
    ).thenReturn(UserDetailState(status: UserDetailStatus.ready, user: user));

    await tester.pumpApp(
      BlocProvider<AuthBloc>.value(
        value: authBlocIn(const AuthSignedIn(testAdmin)),
        child: UserDetailPage(userId: user.id),
      ),
    );
  }

  testWidgets('offers the actions for another user', (tester) async {
    await openPageOf(tester, operatorUser);

    expect(find.text('Demo Operatör'), findsOneWidget);
    expect(find.text('Pasif yap'), findsOneWidget);
    expect(find.text('Geçici şifre ver'), findsOneWidget);
  });

  testWidgets('hides the actions on the admin\'s own account', (tester) async {
    await openPageOf(
      tester,
      ManagedUser(
        id: testAdmin.id,
        userName: testAdmin.userName,
        fullName: testAdmin.fullName,
        role: UserRole.admin,
        isActive: true,
        mustChangePassword: false,
      ),
    );

    expect(find.textContaining('Bu sizin hesabınız'), findsOneWidget);
    expect(find.text('Pasif yap'), findsNothing);
  });
}
