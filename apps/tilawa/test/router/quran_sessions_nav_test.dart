import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_sessions/data/fake_auth_session_provider.dart';
import 'package:tilawa/features/quran_sessions/router/quran_sessions_nav.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class FakeGoRouterState extends Fake implements GoRouterState {
  FakeGoRouterState(this.path);

  @override
  final String path;

  @override
  Uri get uri => Uri.parse(path);
}

GoRoute _bookingRoute() {
  return quranSessionsRoutes.whereType<GoRoute>().firstWhere(
    (route) => route.path == QuranSessionsRoutes.booking,
  );
}

GoRoute _sessionDetailRoute() {
  return quranSessionsRoutes.whereType<GoRoute>().firstWhere(
    (route) => route.path == QuranSessionsRoutes.sessionDetail,
  );
}

Future<String?> redirectBookingRoute(WidgetTester tester, String path) async {
  final state = FakeGoRouterState(path);
  final route = _bookingRoute();

  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (builderContext) {
          context = builderContext;
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  return await route.redirect!(context, state);
}

Future<String?> redirectSessionDetailRoute(
  WidgetTester tester,
  String path,
) async {
  final state = FakeGoRouterState(path);
  final route = _sessionDetailRoute();

  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (builderContext) {
          context = builderContext;
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  return await route.redirect!(context, state);
}

GoRoute _profileCompletionRoute() {
  return quranSessionsRoutes.whereType<GoRoute>().firstWhere(
    (route) => route.path == QuranSessionsRoutes.profileCompletion,
  );
}

Future<String?> redirectProfileCompletionRoute(
  WidgetTester tester,
) async {
  final state = FakeGoRouterState(QuranSessionsRoutes.profileCompletion);
  final route = _profileCompletionRoute();

  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (builderContext) {
          context = builderContext;
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  return route.redirect!(context, state);
}

class _PendingTeacherCapabilityUseCase
    extends GetCurrentUserTeacherCapabilityUseCase {
  _PendingTeacherCapabilityUseCase(this._pending)
    : super(
        applicationRepository: _UnimplementedApplicationRepository(),
        profileRepository: _UnimplementedProfileRepository(),
      );

  final Completer<Either<QuranSessionsFailure, TeacherCapability>> _pending;

  @override
  Future<Either<QuranSessionsFailure, TeacherCapability>> call(
    String userId,
  ) => _pending.future;
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

GoRoute _teacherDashboardRoute() {
  return quranSessionsRoutes.whereType<GoRoute>().firstWhere(
    (route) => route.path == QuranSessionsRoutes.teacherDashboard,
  );
}

void main() {
  tearDown(() {
    if (getIt.isRegistered<AppLaunchConfig>()) {
      getIt.unregister<AppLaunchConfig>();
    }
    if (getIt.isRegistered<AuthSessionProvider>()) {
      getIt.unregister<AuthSessionProvider>();
    }
  });

  group('booking route redirect', () {
    tearDown(() {
      if (getIt.isRegistered<AppLaunchConfig>()) {
        getIt.unregister<AppLaunchConfig>();
      }
    });

    testWidgets('redirects to sessions home when booking kill switch off', (
      tester,
    ) async {
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          quranSessionsEnabled: true,
          learnQuranStudentFeatureEnabled: true,
          quranSessionsBookingEnabled: false,
        ),
      );

      final result = await redirectBookingRoute(
        tester,
        QuranSessionsRoutes.booking.replaceFirst(':teacherId', 'teacher-1'),
      );
      expect(result, QuranSessionsRoutes.home);
    });

    testWidgets('allows navigation when booking enabled', (tester) async {
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          quranSessionsEnabled: true,
          learnQuranStudentFeatureEnabled: true,
          quranSessionsBookingEnabled: true,
        ),
      );
      getIt.registerSingleton<AuthSessionProvider>(
        const FakeAuthSessionProvider(userId: 'student_1'),
      );

      final result = await redirectBookingRoute(
        tester,
        QuranSessionsRoutes.booking.replaceFirst(':teacherId', 'teacher-1'),
      );
      expect(result, isNull);
    });
  });

  group('session detail route redirect', () {
    testWidgets('redirects unsigned users to login', (tester) async {
      getIt.registerSingleton<AuthSessionProvider>(
        const FakeAuthSessionProvider(userId: ''),
      );

      final result = await redirectSessionDetailRoute(
        tester,
        QuranSessionsRoutes.sessionDetail.replaceFirst(
          ':bookingId',
          'booking-1',
        ),
      );
      expect(result, const LoginRoute().location);
    });

    testWidgets('allows signed-in users through', (tester) async {
      getIt.registerSingleton<AuthSessionProvider>(
        const FakeAuthSessionProvider(userId: 'student_1'),
      );

      final result = await redirectSessionDetailRoute(
        tester,
        QuranSessionsRoutes.sessionDetail.replaceFirst(
          ':bookingId',
          'booking-1',
        ),
      );
      expect(result, isNull);
    });
  });

  group('profile completion route redirect', () {
    testWidgets('redirects unsigned users to login before builder runs', (
      tester,
    ) async {
      getIt.registerSingleton<AuthSessionProvider>(
        const FakeAuthSessionProvider(userId: ''),
      );

      final result = await redirectProfileCompletionRoute(tester);
      expect(result, const LoginRoute().location);
    });
  });

  group('teacher dashboard gate loading', () {
    tearDown(() async {
      if (getIt.isRegistered<GetCurrentUserTeacherCapabilityUseCase>()) {
        getIt.unregister<GetCurrentUserTeacherCapabilityUseCase>();
      }
    });

    testWidgets(
      'shows dashboard scaffold while capability verification is pending',
      (tester) async {
        final pendingCapability =
            Completer<Either<QuranSessionsFailure, TeacherCapability>>();
        getIt.registerSingleton<AppLaunchConfig>(
          const AppLaunchConfig(
            quranSessionsEnabled: true,
            learnQuranStudentFeatureEnabled: true,
          ),
        );
        getIt.registerSingleton<AuthSessionProvider>(
          const FakeAuthSessionProvider(userId: 'teacher_user'),
        );
        getIt.registerSingleton<GetCurrentUserTeacherCapabilityUseCase>(
          _PendingTeacherCapabilityUseCase(pendingCapability),
        );

        final route = _teacherDashboardRoute();
        final router = GoRouter(
          initialLocation: QuranSessionsRoutes.teacherDashboard,
          routes: [route],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            theme: AppTheme.getLightTheme(
              primaryColor: AppColors.defaultPrimary,
            ),
            localizationsDelegates: const [
              ...QuranSessionsLocalizations.localizationsDelegates,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: QuranSessionsLocalizations.supportedLocales,
            routerConfig: router,
          ),
        );
        await tester.pump();

        final l10n = await QuranSessionsLocalizations.delegate.load(
          const Locale('en'),
        );
        expect(find.text(l10n.teacherDashboardTitle), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
