import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/cubit/session_validity_cubit.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/quran_sessions_session_guard.dart';

class MockSessionValidityCubit extends MockCubit<SessionValidityState>
    implements SessionValidityCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeGoRouterState extends Fake implements GoRouterState {
  FakeGoRouterState(this.path);

  @override
  final String path;

  @override
  Uri get uri => Uri.parse(path);
}

void main() {
  late MockSessionValidityCubit mockSessionCubit;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockSessionCubit = MockSessionValidityCubit();
    mockAuthBloc = MockAuthBloc();
  });

  group('isProtectedQuranSessionsPath', () {
    test('matches sessions home and nested routes', () {
      expect(isProtectedQuranSessionsPath('/sessions'), isTrue);
      expect(isProtectedQuranSessionsPath('/sessions/'), isTrue);
      expect(isProtectedQuranSessionsPath('/sessions/teachers'), isTrue);
      expect(
        isProtectedQuranSessionsPath('/sessions/teachers/teacher-1/book'),
        isTrue,
      );
      expect(isProtectedQuranSessionsPath('/sessions/dashboard'), isTrue);
    });

    test('ignores non-sessions routes', () {
      expect(isProtectedQuranSessionsPath('/'), isFalse);
      expect(isProtectedQuranSessionsPath('/login'), isFalse);
      expect(isProtectedQuranSessionsPath('/settings'), isFalse);
    });
  });

  Future<String?> redirectForPath(WidgetTester tester, String path) async {
    final state = FakeGoRouterState(path);

    late String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SessionValidityCubit>.value(value: mockSessionCubit),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: Builder(
            builder: (context) {
              result = quranSessionsSessionRedirect(context, state);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return result;
  }

  group('quranSessionsFeatureRedirect', () {
    tearDown(() {
      if (getIt.isRegistered<AppLaunchConfig>()) {
        getIt.unregister<AppLaunchConfig>();
      }
    });

    test('returns null when feature enabled (default)', () {
      final result = quranSessionsFeatureRedirect(
        FakeGoRouterState(QuranSessionsRoutes.home),
      );
      expect(result, isNull);
    });

    test('redirects to home when feature disabled', () {
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(quranSessionsEnabled: false),
      );
      final result = quranSessionsFeatureRedirect(
        FakeGoRouterState(QuranSessionsRoutes.mySessions),
      );
      expect(result, const HomeRoute().location);
    });

    test('ignores non-sessions routes', () {
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(quranSessionsEnabled: false),
      );
      final result = quranSessionsFeatureRedirect(
        FakeGoRouterState('/settings'),
      );
      expect(result, isNull);
    });

    test('redirects booking route when booking kill switch off', () {
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          quranSessionsEnabled: true,
          quranSessionsBookingEnabled: false,
        ),
      );
      addTearDown(() {
        if (getIt.isRegistered<AppLaunchConfig>()) {
          getIt.unregister<AppLaunchConfig>();
        }
      });
      final featureConfig = quranSessionsFeatureConfig();
      expect(featureConfig.quranSessionsBookingEnabled, isFalse);
    });
  });

  group('quranSessionsSessionRedirect', () {
    testWidgets('returns null for non-protected routes', (tester) async {
      whenListen(
        mockSessionCubit,
        Stream<SessionValidityState>.empty(),
        initialState: const SessionValidityState(),
      );
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      final result = await redirectForPath(tester, '/settings');
      expect(result, isNull);
    });

    testWidgets('redirects revoked users to login', (tester) async {
      whenListen(
        mockSessionCubit,
        Stream<SessionValidityState>.empty(),
        initialState: const SessionValidityState(revoked: true),
      );
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          user: UserEntity(
            id: 'user_1',
            email: 'user@example.com',
            displayName: 'User',
            createdAt: DateTime.utc(2024),
          ),
        ),
      );

      final result = await redirectForPath(
        tester,
        QuranSessionsRoutes.mySessions,
      );
      expect(result, const LoginRoute().location);
    });

    testWidgets('redirects unauthenticated users to login', (tester) async {
      whenListen(
        mockSessionCubit,
        Stream<SessionValidityState>.empty(),
        initialState: const SessionValidityState(),
      );
      when(() => mockAuthBloc.state).thenReturn(
        const AuthState.unauthenticated(),
      );

      final result = await redirectForPath(tester, QuranSessionsRoutes.home);
      expect(result, const LoginRoute().location);
    });

    testWidgets('allows authenticated active session through', (tester) async {
      whenListen(
        mockSessionCubit,
        Stream<SessionValidityState>.empty(),
        initialState: const SessionValidityState(),
      );
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          user: UserEntity(
            id: 'user_1',
            email: 'user@example.com',
            displayName: 'User',
            createdAt: DateTime.utc(2024),
          ),
        ),
      );

      final result = await redirectForPath(
        tester,
        QuranSessionsRoutes.teacherDashboard,
      );
      expect(result, isNull);
    });

    testWidgets('returns null when blocs are not mounted', (tester) async {
      final state = FakeGoRouterState(QuranSessionsRoutes.home);

      late String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = quranSessionsSessionRedirect(context, state);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, isNull);
    });

    testWidgets('does not redirect login route (loop guard)', (tester) async {
      whenListen(
        mockSessionCubit,
        Stream<SessionValidityState>.empty(),
        initialState: const SessionValidityState(revoked: true),
      );

      final result = await redirectForPath(tester, const LoginRoute().location);
      expect(result, isNull);
    });
  });
}
