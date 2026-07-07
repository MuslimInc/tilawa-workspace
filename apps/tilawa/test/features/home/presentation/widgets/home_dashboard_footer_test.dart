import 'dart:developer' as developer;
import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_footer.dart';
import 'package:tilawa/features/quran_sessions/data/fake_auth_session_provider.dart';
import 'package:tilawa/features/quran_sessions/domain/entities/quran_sessions_platform_config.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_platform_config_store.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../support/screen_scope_test_support.dart';

const _homeKey = Key('home_screen');
const _loginKey = Key('login_screen');
const _sessionsKey = Key('sessions_screen');
const _profileCompletionKey = Key('profile_completion_screen');

final _completeProfile = UserProfile(
  userId: 'user_1',
  role: UserRole.student,
  accountStatus: AccountStatus.active,
  gender: UserGender.male,
  dateOfBirth: DateTime.utc(2000, 1, 1),
  countryCode: 'SA',
  cityId: 'riyadh',
);

const _incompleteProfile = UserProfile(
  userId: 'user_1',
  role: UserRole.student,
  accountStatus: AccountStatus.active,
  gender: UserGender.male,
);

class _FakeUserProfileRepository implements UserProfileRepository {
  _FakeUserProfileRepository(this._profile);

  final UserProfile _profile;

  @override
  Future<Either<QuranSessionsFailure, UserProfile>> getProfile(
    String userId,
  ) async => Right(_profile);

  @override
  Future<Either<QuranSessionsFailure, UserProfile>> updateProfile(
    UserProfile profile,
  ) async => Right(profile);

  @override
  Future<Either<QuranSessionsFailure, void>> blockAccount({
    required String userId,
    required AccountRestrictionReason reason,
  }) async => const Right(null);
}

class _LoggedOutAuthSession implements AuthSessionProvider {
  @override
  String? get currentUserId => null;

  @override
  Stream<String?> watchUserId() => Stream.value(null);
}

Future<void> _registerSessionsDependencies({
  required AuthSessionProvider authSession,
  required UserProfile profile,
}) async {
  getIt.registerSingleton<AuthSessionProvider>(authSession);
  getIt.registerSingleton<GetUserProfileUseCase>(
    GetUserProfileUseCase(_FakeUserProfileRepository(profile)),
  );
  getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
    QuranSessionsPlatformConfigStore()..setConfig(
      const QuranSessionsPlatformConfig(
        quranSessionsEnabled: true,
        studentEntryEnabled: true,
        bookingEnabled: true,
        bookingMode: 'requiresTutorApproval',
        sessionMode: 'videoOnly',
        enabledCallProviders: {'mock'},
      ),
    ),
  );
}

GoRouter _sessionsNavRouter({
  required Widget home,
  bool profileCompletionReturnsTrue = true,
}) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => Scaffold(key: _homeKey, body: home),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const Scaffold(key: _loginKey, body: Text('login')),
      ),
      GoRoute(
        path: QuranSessionsRoutes.home,
        builder: (context, state) =>
            const Scaffold(key: _sessionsKey, body: Text('sessions')),
      ),
      GoRoute(
        path: QuranSessionsRoutes.profileCompletion,
        builder: (context, state) => Scaffold(
          key: _profileCompletionKey,
          body: TextButton(
            onPressed: () => context.pop(profileCompletionReturnsTrue),
            child: const Text('finish-profile'),
          ),
        ),
      ),
    ],
  );
}

Future<void> _pumpFooter(WidgetTester tester, {GoRouter? router}) async {
  final footer = const Scaffold(body: HomeDashboardFooter());

  if (router != null) {
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  } else {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: footer,
      ),
    );
  }
  await tester.pump();
}

void main() {
  tearDown(() async {
    if (getIt.isRegistered<AppLaunchConfig>()) {
      await getIt.unregister<AppLaunchConfig>();
    }
  });

  testWidgets('shows sessions footer link when quran sessions enabled', (
    tester,
  ) async {
    await resetScopeGetIt();
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(
        quranSessionsEnabled: true,
        learnQuranStudentFeatureEnabled: true,
      ),
    );
    getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
      QuranSessionsPlatformConfigStore()..setConfig(
        const QuranSessionsPlatformConfig(
          quranSessionsEnabled: true,
          studentEntryEnabled: true,
          bookingEnabled: true,
          bookingMode: 'requiresTutorApproval',
          sessionMode: 'videoOnly',
          enabledCallProviders: {'mock'},
        ),
      ),
    );

    await _pumpFooter(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeDashboardFooter)),
    );

    check(find.text(l10n.homeQuickTasbeeh).evaluate().length).equals(1);
    check(find.text(l10n.homeSessionsTitle).evaluate().length).equals(1);
  });

  testWidgets('hides sessions footer link when quran sessions disabled', (
    tester,
  ) async {
    await resetScopeGetIt();
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(
        quranSessionsEnabled: true,
        learnQuranStudentFeatureEnabled: false,
      ),
    );
    getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
      QuranSessionsPlatformConfigStore()..setConfig(
        const QuranSessionsPlatformConfig(
          quranSessionsEnabled: true,
          studentEntryEnabled: false,
          bookingEnabled: true,
          bookingMode: 'requiresTutorApproval',
          sessionMode: 'videoOnly',
          enabledCallProviders: {'mock'},
        ),
      ),
    );

    await _pumpFooter(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeDashboardFooter)),
    );

    check(find.text(l10n.homeQuickTasbeeh).evaluate().length).equals(1);
    check(find.text(l10n.homeSessionsTitle).evaluate().isEmpty).isTrue();
  });

  testWidgets('footer sessions tap opens sessions when profile complete', (
    tester,
  ) async {
    await resetScopeGetIt();
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(
        quranSessionsEnabled: true,
        learnQuranStudentFeatureEnabled: true,
      ),
    );
    getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
      QuranSessionsPlatformConfigStore()..setConfig(
        const QuranSessionsPlatformConfig(
          quranSessionsEnabled: true,
          studentEntryEnabled: true,
          bookingEnabled: true,
          bookingMode: 'requiresTutorApproval',
          sessionMode: 'videoOnly',
          enabledCallProviders: {'mock'},
        ),
      ),
    );
    await _registerSessionsDependencies(
      authSession: const FakeAuthSessionProvider(userId: 'user_1'),
      profile: _completeProfile,
    );

    final router = _sessionsNavRouter(
      home: const HomeDashboardFooter(),
    );

    await _pumpFooter(tester, router: router);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeDashboardFooter)),
    );

    await tester.tap(find.text(l10n.homeSessionsTitle));
    await tester.pumpAndSettle();

    check(find.byKey(_sessionsKey).evaluate().length).equals(1);
  });

  group('openHomeQuranSessions', () {
    Future<void> tapTrigger(WidgetTester tester) async {
      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();
    }

    testWidgets('does not push routes when feature disabled', (tester) async {
      await resetScopeGetIt();
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          quranSessionsEnabled: true,
          learnQuranStudentFeatureEnabled: false,
        ),
      );
      getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
        QuranSessionsPlatformConfigStore()..setConfig(
          const QuranSessionsPlatformConfig(
            quranSessionsEnabled: true,
            studentEntryEnabled: false,
            bookingEnabled: true,
            bookingMode: 'requiresTutorApproval',
            sessionMode: 'videoOnly',
            enabledCallProviders: {'mock'},
          ),
        ),
      );

      final router = _sessionsNavRouter(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => openHomeQuranSessions(context),
            child: const Text('trigger'),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pump();

      await tapTrigger(tester);

      check(find.byKey(_homeKey).evaluate().length).equals(1);
      check(find.byKey(_loginKey).evaluate().isEmpty).isTrue();
      check(find.byKey(_sessionsKey).evaluate().isEmpty).isTrue();
    });

    testWidgets('routes logged-out users to login', (tester) async {
      await resetScopeGetIt();
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          quranSessionsEnabled: true,
          learnQuranStudentFeatureEnabled: true,
        ),
      );
      getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
        QuranSessionsPlatformConfigStore()..setConfig(
          const QuranSessionsPlatformConfig(
            quranSessionsEnabled: true,
            studentEntryEnabled: true,
            bookingEnabled: true,
            bookingMode: 'requiresTutorApproval',
            sessionMode: 'videoOnly',
            enabledCallProviders: {'mock'},
          ),
        ),
      );
      getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
        QuranSessionsPlatformConfigStore()..setConfig(
          const QuranSessionsPlatformConfig(
            quranSessionsEnabled: true,
            studentEntryEnabled: true,
            bookingEnabled: true,
            bookingMode: 'requiresTutorApproval',
            sessionMode: 'videoOnly',
            enabledCallProviders: {'mock'},
          ),
        ),
      );
      getIt.registerSingleton<AuthSessionProvider>(_LoggedOutAuthSession());

      final router = _sessionsNavRouter(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => openHomeQuranSessions(context),
            child: const Text('trigger'),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pump();

      developer.log("USER_ID: ${getIt<AuthSessionProvider>().currentUserId}");
      await tapTrigger(tester);

      check(find.byKey(_loginKey).evaluate().length).equals(1);
    });

    testWidgets('routes signed-in complete profile to sessions home', (
      tester,
    ) async {
      await resetScopeGetIt();
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          quranSessionsEnabled: true,
          learnQuranStudentFeatureEnabled: true,
        ),
      );
      getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
        QuranSessionsPlatformConfigStore()..setConfig(
          const QuranSessionsPlatformConfig(
            quranSessionsEnabled: true,
            studentEntryEnabled: true,
            bookingEnabled: true,
            bookingMode: 'requiresTutorApproval',
            sessionMode: 'videoOnly',
            enabledCallProviders: {'mock'},
          ),
        ),
      );
      await _registerSessionsDependencies(
        authSession: const FakeAuthSessionProvider(userId: 'user_1'),
        profile: _completeProfile,
      );

      final router = _sessionsNavRouter(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => openHomeQuranSessions(context),
            child: const Text('trigger'),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pump();

      developer.log("USER_ID: ${getIt<AuthSessionProvider>().currentUserId}");
      await tapTrigger(tester);

      check(find.byKey(_sessionsKey).evaluate().length).equals(1);
    });

    testWidgets('gates incomplete profile through profile completion', (
      tester,
    ) async {
      await resetScopeGetIt();
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          quranSessionsEnabled: true,
          learnQuranStudentFeatureEnabled: true,
        ),
      );
      getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
        QuranSessionsPlatformConfigStore()..setConfig(
          const QuranSessionsPlatformConfig(
            quranSessionsEnabled: true,
            studentEntryEnabled: true,
            bookingEnabled: true,
            bookingMode: 'requiresTutorApproval',
            sessionMode: 'videoOnly',
            enabledCallProviders: {'mock'},
          ),
        ),
      );
      await _registerSessionsDependencies(
        authSession: const FakeAuthSessionProvider(userId: 'user_1'),
        profile: _incompleteProfile,
      );

      final router = _sessionsNavRouter(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => openHomeQuranSessions(context),
            child: const Text('trigger'),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pump();

      developer.log("USER_ID: ${getIt<AuthSessionProvider>().currentUserId}");
      await tapTrigger(tester);

      check(find.byKey(_profileCompletionKey).evaluate().length).equals(1);
      check(find.byKey(_sessionsKey).evaluate().isEmpty).isTrue();
    });

    testWidgets('continues to sessions after profile completion succeeds', (
      tester,
    ) async {
      await resetScopeGetIt();
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          quranSessionsEnabled: true,
          learnQuranStudentFeatureEnabled: true,
        ),
      );
      getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
        QuranSessionsPlatformConfigStore()..setConfig(
          const QuranSessionsPlatformConfig(
            quranSessionsEnabled: true,
            studentEntryEnabled: true,
            bookingEnabled: true,
            bookingMode: 'requiresTutorApproval',
            sessionMode: 'videoOnly',
            enabledCallProviders: {'mock'},
          ),
        ),
      );
      await _registerSessionsDependencies(
        authSession: const FakeAuthSessionProvider(userId: 'user_1'),
        profile: _incompleteProfile,
      );

      final router = _sessionsNavRouter(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => openHomeQuranSessions(context),
            child: const Text('trigger'),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pump();

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      check(find.byKey(_profileCompletionKey).evaluate().length).equals(1);

      await tester.tap(find.text('finish-profile'));
      await tester.pumpAndSettle();

      check(find.byKey(_sessionsKey).evaluate().length).equals(1);
    });

    testWidgets('stays off sessions when profile completion is dismissed', (
      tester,
    ) async {
      await resetScopeGetIt();
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          quranSessionsEnabled: true,
          learnQuranStudentFeatureEnabled: true,
        ),
      );
      getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
        QuranSessionsPlatformConfigStore()..setConfig(
          const QuranSessionsPlatformConfig(
            quranSessionsEnabled: true,
            studentEntryEnabled: true,
            bookingEnabled: true,
            bookingMode: 'requiresTutorApproval',
            sessionMode: 'videoOnly',
            enabledCallProviders: {'mock'},
          ),
        ),
      );
      await _registerSessionsDependencies(
        authSession: const FakeAuthSessionProvider(userId: 'user_1'),
        profile: _incompleteProfile,
      );

      final router = _sessionsNavRouter(
        profileCompletionReturnsTrue: false,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => openHomeQuranSessions(context),
            child: const Text('trigger'),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pump();

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('finish-profile'));
      await tester.pumpAndSettle();

      check(find.byKey(_sessionsKey).evaluate().isEmpty).isTrue();
      check(find.byKey(_homeKey).evaluate().length).equals(1);
    });
  });
}
