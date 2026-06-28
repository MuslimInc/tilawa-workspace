import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_sessions/data/fake_auth_session_provider.dart';
import 'package:tilawa/features/quran_sessions/router/quran_sessions_nav.dart';
import 'package:tilawa/router/app_router_config.dart';

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
          quranSessionsBookingEnabled: true,
        ),
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
}
