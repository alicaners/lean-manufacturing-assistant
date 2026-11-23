import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/new_user.dart';
import 'package:lean_assistant/features/admin/domain/plant.dart';
import 'package:lean_assistant/features/admin/presentation/create_user_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/create_user_page.dart';
import 'package:lean_assistant/features/admin/presentation/create_user_state.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockCreateUserCubit extends MockCubit<CreateUserState>
    implements CreateUserCubit {}

/// Two plants, so the form does not pick one by itself.
const _plantsLoaded = CreateUserState(
  plantsStatus: OptionsStatus.ready,
  plants: [
    Plant(id: 'p-1', name: 'İzmir Fabrikası', code: 'DEMO-IZM'),
    Plant(id: 'p-2', name: 'Bursa Fabrikası', code: 'DEMO-BRS'),
  ],
);

void main() {
  late _MockCreateUserCubit cubit;

  setUpAll(
    () => registerFallbackValue(
      const NewUser(
        userName: 'x',
        fullName: 'x',
        temporaryPassword: 'x',
        role: UserRole.operator,
      ),
    ),
  );

  setUp(() {
    cubit = _MockCreateUserCubit();
    when(() => cubit.loadPlants()).thenAnswer((_) async {});
    getIt.registerFactory<CreateUserCubit>(() => cubit);
  });

  tearDown(getIt.reset);

  testWidgets('checks the fields before creating the user', (tester) async {
    when(() => cubit.state).thenReturn(_plantsLoaded);

    await tester.pumpApp(const CreateUserPage());
    await tester.ensureVisible(find.text('Kullanıcıyı oluştur'));
    await tester.tap(find.text('Kullanıcıyı oluştur'));
    await tester.pump();

    // User name, full name, password and plant (an operator needs one).
    expect(find.text('Bu alan zorunludur.'), findsNWidgets(4));
    verifyNever(() => cubit.submit(any()));
  });

  testWidgets('shows a taken user name under its field', (tester) async {
    when(() => cubit.state).thenReturn(
      _plantsLoaded.copyWith(submit: const SubmitFailed(ConflictFailure())),
    );

    await tester.pumpApp(const CreateUserPage());

    expect(find.text('Bu kullanıcı adı zaten kullanılıyor.'), findsOneWidget);
  });
}
