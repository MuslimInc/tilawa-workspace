import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/auth/data/datasources/profile_avatar_storage.dart';
import 'package:tilawa/features/auth/domain/entities/email_registration_draft.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/user_repository.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/settings/presentation/cubit/edit_profile_cubit.dart';
import 'package:tilawa/features/settings/presentation/screens/edit_profile_screen.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _FakeUserRepository implements UserRepository {
  int updateCalls = 0;

  @override
  Future<void> deleteUserData(String userId) async {}

  @override
  Future<void> saveUserData(
    UserEntity user, {
    String? authProvider,
    bool? profileCompleted,
  }) async {}

  @override
  Future<void> ensureQuranSessionsProfileShell(String userId) async {}

  @override
  Future<void> saveCompleteEmailRegistration({
    required UserEntity user,
    required EmailRegistrationDraft draft,
  }) async {}

  @override
  Future<void> syncLanguagePreference(String languageCode) async {}

  @override
  Future<UserEntity> updateAccountProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    updateCalls += 1;
    return UserEntity(
      id: 'user-1',
      email: 'user@example.com',
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: DateTime.utc(2025, 12),
    );
  }
}

class _FakeAvatarStorage extends Fake implements ProfileAvatarStorage {
  @override
  Future<String> upload({
    required String userId,
    required String localPath,
  }) async {
    return 'https://example.com/avatar.jpg';
  }

  @override
  Future<void> delete(String userId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthBloc authBloc;
  late _FakeUserRepository repository;
  late _FakeAvatarStorage avatarStorage;
  final GetIt testGetIt = getIt;

  final UserEntity signedInUser = UserEntity(
    id: 'user-1',
    email: 'user@example.com',
    displayName: 'Mohammad Kamel',
    photoUrl: 'https://example.com/photo.jpg',
    createdAt: DateTime.utc(2025, 12),
  );

  setUp(() async {
    TilawaInteractionFeedback.enabled = false;
    await testGetIt.reset();
    authBloc = _MockAuthBloc();
    repository = _FakeUserRepository();
    avatarStorage = _FakeAvatarStorage();
    testGetIt.registerFactory<EditProfileCubit>(
      () => EditProfileCubit(repository, avatarStorage),
    );
  });

  tearDown(() async {
    await testGetIt.reset();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    required AuthState authState,
    Locale locale = const Locale('en'),
    Size surfaceSize = const Size(390, 844),
    bool pushAsRoute = false,
  }) async {
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: authState,
    );

    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final Widget screen = BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: const EditProfileScreen(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: locale,
        builder: (context, child) => TilawaFeedbackHost(child: child!),
        home: pushAsRoute
            ? Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => screen),
                    );
                  });
                  return const Scaffold(body: SizedBox.shrink());
                },
              )
            : screen,
      ),
    );
    await tester.pump();
    if (pushAsRoute) {
      await tester.pumpAndSettle();
    }
  }

  Finder saveButton() => find.widgetWithText(TilawaButton, 'Save');

  testWidgets('shows unavailable state when unauthenticated', (tester) async {
    await pumpScreen(tester, authState: const AuthState.unauthenticated());

    expect(find.text('Profile unavailable'), findsOneWidget);
    expect(
      find.text('Sign in again to edit your profile.'),
      findsOneWidget,
    );
    expect(find.byType(TilawaFormScreenScaffold), findsNothing);
  });

  testWidgets('uses bounded form scaffold for authenticated user', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      authState: AuthState.authenticated(user: signedInUser),
    );

    expect(find.byType(TilawaContentBounds), findsWidgets);
    expect(find.byType(TilawaFormScreenScaffold), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Display name'), findsOneWidget);
  });

  testWidgets('disables Save until the form is dirty', (tester) async {
    await pumpScreen(
      tester,
      authState: AuthState.authenticated(user: signedInUser),
    );

    final TilawaButton before = tester.widget<TilawaButton>(saveButton());
    check(before.onPressed).isNull();

    await tester.enterText(find.byType(TilawaTextField), 'New Name');
    await tester.pump();

    final TilawaButton after = tester.widget<TilawaButton>(saveButton());
    check(after.onPressed).isNotNull();
  });

  testWidgets('opens photo actions sheet from change photo', (tester) async {
    await pumpScreen(
      tester,
      authState: AuthState.authenticated(user: signedInUser),
    );

    await tester.tap(find.text('Change photo'));
    await tester.pumpAndSettle();

    expect(find.text('Profile photo'), findsWidgets);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Remove photo'), findsOneWidget);
  });

  testWidgets('guards back navigation when dirty', (tester) async {
    await pumpScreen(
      tester,
      authState: AuthState.authenticated(user: signedInUser),
    );

    await tester.enterText(find.byType(TilawaTextField), 'New Name');
    await tester.pump();

    final BuildContext context = tester.element(find.byType(EditProfileScreen));
    final NavigatorState navigator = Navigator.of(context);
    // ignore: unawaited_futures
    navigator.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text('Keep editing'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('successful save pops route', (tester) async {
    await pumpScreen(
      tester,
      authState: AuthState.authenticated(user: signedInUser),
      pushAsRoute: true,
    );

    await tester.enterText(find.byType(TilawaTextField), 'Updated Name');
    await tester.pump();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    check(repository.updateCalls).equals(1);
    expect(find.text('Edit Profile'), findsNothing);
    expect(find.text('Profile updated'), findsOneWidget);
  });

  testWidgets('Arabic RTL shows localized chrome', (tester) async {
    await pumpScreen(
      tester,
      authState: AuthState.authenticated(user: signedInUser),
      locale: const Locale('ar'),
    );

    expect(find.text('تعديل الملف الشخصي'), findsOneWidget);
    expect(find.text('الاسم الظاهر'), findsOneWidget);
    expect(find.text('حفظ'), findsOneWidget);
  });
}
