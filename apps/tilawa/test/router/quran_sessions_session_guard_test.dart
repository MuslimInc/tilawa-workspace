import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/cubit/session_validity_cubit.dart';
import 'package:tilawa/features/quran_sessions/data/fake_auth_session_provider.dart';
import 'package:tilawa/features/quran_sessions/domain/entities/quran_sessions_platform_config.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_platform_config_store.dart';
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

void seedPlatformConfig({
  required bool quranSessionsEnabled,
  required bool studentEntryEnabled,
  bool bookingEnabled = false,
}) {
  final store = QuranSessionsPlatformConfigStore()
    ..setConfig(
      QuranSessionsPlatformConfig(
        quranSessionsEnabled: quranSessionsEnabled,
        studentEntryEnabled: studentEntryEnabled,
        bookingEnabled: bookingEnabled,
        bookingMode: 'requiresTutorApproval',
        sessionMode: 'videoOnly',
        enabledCallProviders: const {'external', 'mock'},
      ),
    );
  if (getIt.isRegistered<QuranSessionsPlatformConfigStore>()) {
    getIt.unregister<QuranSessionsPlatformConfigStore>();
  }
  getIt.registerSingleton<QuranSessionsPlatformConfigStore>(store);
}

void main() {
  late MockSessionValidityCubit mockSessionCubit;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockSessionCubit = MockSessionValidityCubit();
    mockAuthBloc = MockAuthBloc();
  });

  tearDown(() {
    if (getIt.isRegistered<AuthSessionProvider>()) {
      getIt.unregister<AuthSessionProvider>();
    }
  });

  group('isStudentFacingQuranSessionsPath', () {
    test('matches browse and booking flows only', () {
      expect(
        isStudentFacingQuranSessionsPath(QuranSessionsRoutes.mySessions),
        isTrue,
      );
      expect(
        isStudentFacingQuranSessionsPath(
          QuranSessionsRoutes.sessionDetail.replaceFirst(
            ':bookingId',
            'booking-1',
          ),
        ),
        isFalse,
      );
      expect(
        isStudentFacingQuranSessionsPath(
          QuranSessionsRoutes.rescheduleSession.replaceFirst(
            ':bookingId',
            'booking-1',
          ),
        ),
        isFalse,
      );
      expect(
        isStudentFacingQuranSessionsPath(QuranSessionsRoutes.teacherDashboard),
        isFalse,
      );
    });
  });

  group('isAuthRequiredQuranSessionsPath', () {
    test('matches session detail and other signed-in flows', () {
      expect(
        isAuthRequiredQuranSessionsPath(
          QuranSessionsRoutes.sessionDetail.replaceFirst(
            ':bookingId',
            'booking-1',
          ),
        ),
        isTrue,
      );
      expect(
        isAuthRequiredQuranSessionsPath(QuranSessionsRoutes.mySessions),
        isTrue,
      );
      expect(
        isAuthRequiredQuranSessionsPath(
          QuranSessionsRoutes.booking.replaceFirst(':teacherId', 'teacher-1'),
        ),
        isTrue,
      );
    });

    test('ignores browse-only sessions routes', () {
      expect(
        isAuthRequiredQuranSessionsPath(QuranSessionsRoutes.home),
        isFalse,
      );
      expect(
        isAuthRequiredQuranSessionsPath(QuranSessionsRoutes.teacherList),
        isFalse,
      );
      expect(
        isAuthRequiredQuranSessionsPath(
          QuranSessionsRoutes.teacherProfile.replaceFirst(
            ':teacherId',
            'teacher-1',
          ),
        ),
        isFalse,
      );
    });
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
    tearDown(() async {
      await getIt.reset();
    });

    test('returns null when student feature enabled', () {
      seedPlatformConfig(
        quranSessionsEnabled: true,
        studentEntryEnabled: true,
      );
      final result = quranSessionsFeatureRedirect(
        FakeGoRouterState(QuranSessionsRoutes.home),
      );
      expect(result, isNull);
    });

    test('returns null when feature enabled (default) for teacher routes', () {
      seedPlatformConfig(
        quranSessionsEnabled: true,
        studentEntryEnabled: false,
      );
      final result = quranSessionsFeatureRedirect(
        FakeGoRouterState(QuranSessionsRoutes.teacherDashboard),
      );
      expect(result, isNull);
    });

    test('redirects student routes when student feature disabled', () {
      seedPlatformConfig(
        quranSessionsEnabled: true,
        studentEntryEnabled: false,
      );
      final result = quranSessionsFeatureRedirect(
        FakeGoRouterState(QuranSessionsRoutes.mySessions),
      );
      expect(result, const HomeRoute().location);
    });

    test('allows teacher dashboard when student feature disabled', () {
      seedPlatformConfig(
        quranSessionsEnabled: true,
        studentEntryEnabled: false,
      );
      final result = quranSessionsFeatureRedirect(
        FakeGoRouterState(QuranSessionsRoutes.teacherDashboard),
      );
      expect(result, isNull);
    });

    test('allows session detail when student feature disabled', () {
      seedPlatformConfig(
        quranSessionsEnabled: true,
        studentEntryEnabled: false,
      );
      final result = quranSessionsFeatureRedirect(
        FakeGoRouterState(
          QuranSessionsRoutes.sessionDetail.replaceFirst(
            ':bookingId',
            'booking-1',
          ),
        ),
      );
      expect(result, isNull);
    });

    test('allows reschedule when student feature disabled', () {
      seedPlatformConfig(
        quranSessionsEnabled: true,
        studentEntryEnabled: false,
      );
      final result = quranSessionsFeatureRedirect(
        FakeGoRouterState(
          QuranSessionsRoutes.rescheduleSession.replaceFirst(
            ':bookingId',
            'booking-1',
          ),
        ),
      );
      expect(result, isNull);
    });

    test('redirects to home when feature disabled', () {
      seedPlatformConfig(
        quranSessionsEnabled: false,
        studentEntryEnabled: false,
      );
      final result = quranSessionsFeatureRedirect(
        FakeGoRouterState(QuranSessionsRoutes.mySessions),
      );
      expect(result, const HomeRoute().location);
    });

    test('ignores non-sessions routes', () {
      seedPlatformConfig(
        quranSessionsEnabled: false,
        studentEntryEnabled: false,
      );
      final result = quranSessionsFeatureRedirect(
        FakeGoRouterState('/settings'),
      );
      expect(result, isNull);
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

    testWidgets('redirects verification-unknown sessions to login', (
      tester,
    ) async {
      whenListen(
        mockSessionCubit,
        Stream<SessionValidityState>.empty(),
        initialState: const SessionValidityState(verificationUnknown: true),
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

    testWidgets('defers redirect while auth is restoring on sessions home', (
      tester,
    ) async {
      whenListen(
        mockSessionCubit,
        Stream<SessionValidityState>.empty(),
        initialState: const SessionValidityState(),
      );
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      final result = await redirectForPath(tester, QuranSessionsRoutes.home);
      expect(result, isNull);
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
      getIt.registerSingleton<AuthSessionProvider>(
        const FakeAuthSessionProvider(userId: 'user_1'),
      );

      final result = await redirectForPath(
        tester,
        QuranSessionsRoutes.teacherDashboard,
      );
      expect(result, isNull);
    });

    testWidgets('returns null when blocs are not mounted and auth unknown', (
      tester,
    ) async {
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

    testWidgets(
      'redirects auth-required routes when auth state is unknown at startup',
      (tester) async {
        final state = FakeGoRouterState(QuranSessionsRoutes.profileCompletion);

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
        expect(result, const LoginRoute().location);
      },
    );

    testWidgets(
      'redirects teacher dashboard when auth provider is missing at startup',
      (tester) async {
        final state = FakeGoRouterState(QuranSessionsRoutes.teacherDashboard);

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
        expect(result, const LoginRoute().location);
      },
    );

    testWidgets(
      'redirects to login when blocs are not mounted and user is signed out',
      (tester) async {
        getIt.registerSingleton<AuthSessionProvider>(
          const FakeAuthSessionProvider(userId: ''),
        );
        final state = FakeGoRouterState(
          QuranSessionsRoutes.sessionDetail.replaceFirst(
            ':bookingId',
            'booking-1',
          ),
        );

        late String? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                result = quranSessionsAuthRequiredRedirect(context, state);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(result, const LoginRoute().location);
      },
    );

    testWidgets('does not redirect on login route (not a sessions path)', (
      tester,
    ) async {
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
