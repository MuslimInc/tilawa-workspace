import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/quran_sessions/data/fake_auth_session_provider.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_teacher_capability_scope.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_teaching_on_memuslim_tile.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../support/screen_scope_test_support.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _StubTeacherCapabilityUseCase
    extends GetCurrentUserTeacherCapabilityUseCase {
  _StubTeacherCapabilityUseCase(this._capability)
    : super(
        applicationRepository: _UnimplementedApplicationRepository(),
        profileRepository: _UnimplementedProfileRepository(),
      );

  final TeacherCapability _capability;

  @override
  Future<Either<QuranSessionsFailure, TeacherCapability>> call(
    String userId,
  ) async => Right(_capability);
}

class _SequenceTeacherCapabilityUseCase
    extends GetCurrentUserTeacherCapabilityUseCase {
  _SequenceTeacherCapabilityUseCase(this._capabilities)
    : super(
        applicationRepository: _UnimplementedApplicationRepository(),
        profileRepository: _UnimplementedProfileRepository(),
      );

  final List<TeacherCapability> _capabilities;
  var callCount = 0;

  @override
  Future<Either<QuranSessionsFailure, TeacherCapability>> call(
    String userId,
  ) async {
    final index = callCount.clamp(0, _capabilities.length - 1);
    callCount++;
    return Right(_capabilities[index]);
  }
}

class _UnimplementedApplicationRepository
    implements TeacherApplicationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnimplementedProfileRepository implements TeacherProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<void> _pumpSettingsTeachingSection(
  WidgetTester tester,
  _MockAuthBloc authBloc,
  TeacherCapability capability, {
  GoRouter? router,
  Locale? locale,
  bool useSection = true,
}) async {
  scopeGetIt().registerSingleton<GetCurrentUserTeacherCapabilityUseCase>(
    _StubTeacherCapabilityUseCase(capability),
  );

  final Widget teachingSection = SettingsTeacherCapabilityScope(
    child: Column(
      children: [
        const SettingsProfileHeader(),
        if (useSection)
          const SettingsTeachingOnMemuslimSection()
        else
          SettingsTeachingOnMemuslimTile(showDivider: false),
      ],
    ),
  );

  if (router != null) {
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: locale,
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...QuranSessionsLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    router.go('/');
    await tester.pumpAndSettle();
    return;
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      locale: locale,
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        ...QuranSessionsLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: teachingSection,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

late _MockAuthBloc mockAuthBloc;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetScopeGetIt();
    mockAuthBloc = _MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        user: UserEntity(
          id: 'user_1',
          email: 'teacher@example.com',
          displayName: 'Teacher User',
          createdAt: DateTime.utc(2024, 1, 1),
        ),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    scopeGetIt().registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(
        teacherApplicationEnabled: true,
        teacherApplicationDiscoverability: 'profileOnly',
      ),
    );
    scopeGetIt().registerSingleton<AuthSessionProvider>(
      const FakeAuthSessionProvider(userId: 'user_1'),
    );
  });

  tearDown(() async {
    await resetScopeGetIt();
  });

  testWidgets('approved active profile header hides duplicate verified badge', (
    tester,
  ) async {
    await _pumpSettingsTeachingSection(
      tester,
      mockAuthBloc,
      const TeacherCapability(state: TeacherCapabilityState.approvedActive),
    );

    check(find.byType(TilawaVerifiedTeacherBadge).evaluate().length).equals(1);
    check(find.byType(TilawaProfileAvatar).evaluate().length).equals(1);
    final avatarSize = tester.getSize(find.byType(TilawaProfileAvatar));
    check(avatarSize.width).equals(avatarSize.height);
    check(
      find.textContaining('Apply as a teacher').evaluate().length,
    ).equals(0);
  });

  testWidgets('approved active settings shows premium dashboard card', (
    tester,
  ) async {
    await _pumpSettingsTeachingSection(
      tester,
      mockAuthBloc,
      const TeacherCapability(state: TeacherCapabilityState.approvedActive),
    );

    final en = await QuranSessionsLocalizations.delegate.load(
      const Locale('en'),
    );
    check(find.byType(TilawaCapabilityActionCard).evaluate().length).equals(1);
    check(find.byType(TilawaSettingsTile).evaluate().isEmpty).isTrue();
    check(find.text(en.teachingOnMemuslimTitle).evaluate().isEmpty).isTrue();
    check(find.text(en.teacherDashboard).evaluate().length).equals(1);
    check(
      find.text(en.manageYourAvailabilityAndSessions).evaluate().length,
    ).equals(1);
    check(find.text(en.verifiedTeacher).evaluate().length).equals(1);
    check(find.byType(TilawaVerifiedTeacherBadge).evaluate().length).equals(1);
  });

  testWidgets(
    'approved incomplete settings shows premium complete profile card',
    (
      tester,
    ) async {
      await _pumpSettingsTeachingSection(
        tester,
        mockAuthBloc,
        const TeacherCapability(
          state: TeacherCapabilityState.approvedIncompleteProfile,
        ),
      );

      final en = await QuranSessionsLocalizations.delegate.load(
        const Locale('en'),
      );
      check(
        find.byType(TilawaCapabilityActionCard).evaluate().length,
      ).equals(1);
      check(find.text(en.completeTeacherProfile).evaluate().length).equals(1);
      check(find.text(en.teacherDashboard).evaluate().length).equals(0);
      check(find.text(en.verifiedTeacher).evaluate().length).equals(1);
      check(
        find.byType(TilawaVerifiedTeacherBadge).evaluate().length,
      ).equals(1);
    },
  );

  testWidgets('none state shows apply tile not premium dashboard card', (
    tester,
  ) async {
    await _pumpSettingsTeachingSection(
      tester,
      mockAuthBloc,
      const TeacherCapability(state: TeacherCapabilityState.none),
    );

    final en = await QuranSessionsLocalizations.delegate.load(
      const Locale('en'),
    );
    check(find.byType(TilawaCapabilityActionCard).evaluate().isEmpty).isTrue();
    check(find.text(en.teachingOnMemuslimApply).evaluate().isNotEmpty).isTrue();
    check(find.text(en.teacherDashboard).evaluate().length).equals(0);
    check(
      find.text(en.teachingOnMemuslimViewStatus).evaluate().length,
    ).equals(0);
  });

  testWidgets('approved active card tap opens teacher dashboard route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: SettingsTeacherCapabilityScope(
              child: SettingsTeachingOnMemuslimTile(showDivider: false),
            ),
          ),
        ),
        GoRoute(
          path: QuranSessionsRoutes.teacherDashboard,
          builder: (context, state) =>
              const Scaffold(key: Key('teacher_dashboard_screen')),
        ),
      ],
    );

    await _pumpSettingsTeachingSection(
      tester,
      mockAuthBloc,
      const TeacherCapability(state: TeacherCapabilityState.approvedActive),
      router: router,
    );

    await tester.tap(find.byType(TilawaCapabilityActionCard));
    await tester.pumpAndSettle();

    check(
      find.byKey(const Key('teacher_dashboard_screen')).evaluate().length,
    ).equals(1);
  });

  testWidgets(
    'approved incomplete card tap opens complete teacher profile route',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: SettingsTeacherCapabilityScope(
                child: SettingsTeachingOnMemuslimTile(showDivider: false),
              ),
            ),
          ),
          GoRoute(
            path: QuranSessionsRoutes.completeTeacherProfile,
            builder: (context, state) =>
                const Scaffold(key: Key('complete_teacher_profile_screen')),
          ),
        ],
      );

      await _pumpSettingsTeachingSection(
        tester,
        mockAuthBloc,
        const TeacherCapability(
          state: TeacherCapabilityState.approvedIncompleteProfile,
        ),
        router: router,
      );

      await tester.tap(find.byType(TilawaCapabilityActionCard));
      await tester.pumpAndSettle();

      check(
        find
            .byKey(const Key('complete_teacher_profile_screen'))
            .evaluate()
            .length,
      ).equals(1);
    },
  );

  testWidgets('Arabic premium card strings render without clipping', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpSettingsTeachingSection(
      tester,
      mockAuthBloc,
      const TeacherCapability(state: TeacherCapabilityState.approvedActive),
      locale: const Locale('ar'),
    );

    final ar = await QuranSessionsLocalizations.delegate.load(
      const Locale('ar'),
    );

    check(find.text(ar.teacherDashboard).evaluate().length).equals(1);
    check(
      find.text(ar.manageYourAvailabilityAndSessions).evaluate().length,
    ).equals(1);
    check(find.byType(TilawaVerifiedTeacherBadge).evaluate().length).equals(1);

    final titleSize = tester.getSize(find.text(ar.teacherDashboard));
    final subtitleSize = tester.getSize(
      find.text(ar.manageYourAvailabilityAndSessions),
    );
    check(titleSize.height).isGreaterThan(0);
    check(subtitleSize.height).isGreaterThan(0);
  });

  testWidgets('refreshOf reloads capability from Firestore', (tester) async {
    final useCase = _SequenceTeacherCapabilityUseCase([
      const TeacherCapability(state: TeacherCapabilityState.pending),
      const TeacherCapability(state: TeacherCapabilityState.approvedActive),
    ]);
    scopeGetIt().registerSingleton<GetCurrentUserTeacherCapabilityUseCase>(
      useCase,
    );

    final en = await QuranSessionsLocalizations.delegate.load(
      const Locale('en'),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...QuranSessionsLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: SettingsTeacherCapabilityScope(
            child: SettingsTeachingOnMemuslimTile(showDivider: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    check(find.text(en.teachingOnMemuslimViewStatus).evaluate().length).equals(
      1,
    );
    check(useCase.callCount).equals(1);

    SettingsTeacherCapabilityScope.refreshOf(
      tester.element(find.byType(SettingsTeachingOnMemuslimTile)),
    );
    await tester.pumpAndSettle();

    check(useCase.callCount).equals(2);
    check(find.text(en.teacherDashboard).evaluate().length).equals(1);
  });
}
