import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/home/presentation/cubit/home_learning_cubit.dart';
import 'package:tilawa/features/home/presentation/services/home_learning_preference_store.dart';
import 'package:tilawa/features/home/presentation/widgets/home_learning_cards.dart';
import 'package:tilawa/features/quran_sessions/domain/entities/quran_sessions_platform_config.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_platform_config_store.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class FakeAuthSessionProvider implements AuthSessionProvider {
  String? userId = 'student_123';
  @override
  String? get currentUserId => userId;
  @override
  Stream<String?> watchUserId() => Stream.value(userId);
}

class FakeGetStudentSessionsUseCase implements GetStudentSessionsUseCase {
  Either<QuranSessionsFailure, StudentSessionsPage>? result;
  @override
  Future<Either<QuranSessionsFailure, StudentSessionsPage>> call(
    String studentId, {
    String? pastCursor,
    int limit = 30,
  }) async {
    return result ?? const Right(StudentSessionsPage(upcoming: [], past: []));
  }
}

class FakeGetSessionAggregateUseCase implements GetSessionAggregateUseCase {
  Either<QuranSessionsFailure, SessionAggregate>? result;
  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> call(
    String bookingId,
  ) async {
    return result ?? const Left(ServerFailure(statusCode: 404));
  }
}

class FakeHomeLearningPreferenceStore implements HomeLearningPreferenceStore {
  bool hasSetInterest = false;
  bool isInterested = false;
  String? lastPracticedSessionId;

  @override
  Future<bool> getHasSetLearningInterest() async => hasSetInterest;
  @override
  Future<void> setHasSetLearningInterest(bool value) async {
    hasSetInterest = value;
  }

  @override
  Future<bool> getIsInterested() async => isInterested;
  @override
  Future<void> setIsInterested(bool value) async {
    isInterested = value;
  }

  @override
  Future<String?> getLastPracticedSessionId() async => lastPracticedSessionId;
  @override
  Future<void> setLastPracticedSessionId(String sessionId) async {
    lastPracticedSessionId = sessionId;
  }
}

void main() {
  group('Home Learning Cards Widgets', () {
    late FakeAuthSessionProvider fakeAuth;
    late FakeGetStudentSessionsUseCase getStudentSessions;
    late FakeGetSessionAggregateUseCase getSessionAggregate;
    late FakeHomeLearningPreferenceStore preferenceStore;
    late QuranSessionsPlatformConfigStore configStore;
    late HomeLearningCubit cubit;
    late DateTime testNow;

    late List<String> navigatedPaths;

    setUp(() {
      navigatedPaths = [];

      fakeAuth = FakeAuthSessionProvider();
      if (getIt.isRegistered<AuthSessionProvider>()) {
        getIt.unregister<AuthSessionProvider>();
      }
      getIt.registerSingleton<AuthSessionProvider>(fakeAuth);

      configStore = QuranSessionsPlatformConfigStore();
      configStore.setConfig(
        const QuranSessionsPlatformConfig(
          quranSessionsEnabled: true,
          studentEntryEnabled: true,
          bookingEnabled: true,
          bookingMode: 'requiresTutorApproval',
          sessionMode: 'videoOnly',
          enabledCallProviders: {'mock'},
        ),
      );
      if (getIt.isRegistered<QuranSessionsPlatformConfigStore>()) {
        getIt.unregister<QuranSessionsPlatformConfigStore>();
      }
      getIt.registerSingleton<QuranSessionsPlatformConfigStore>(configStore);

      getStudentSessions = FakeGetStudentSessionsUseCase();
      getSessionAggregate = FakeGetSessionAggregateUseCase();
      preferenceStore = FakeHomeLearningPreferenceStore();
      testNow = DateTime(2026, 7, 10, 10, 0, 0);

      cubit = HomeLearningCubit(
        getStudentSessions: getStudentSessions,
        getSessionAggregate: getSessionAggregate,
        preferenceStore: preferenceStore,
      )..clock = () => testNow;
    });

    tearDown(() {
      cubit.close();
      if (getIt.isRegistered<AuthSessionProvider>()) {
        getIt.unregister<AuthSessionProvider>();
      }
      if (getIt.isRegistered<QuranSessionsPlatformConfigStore>()) {
        getIt.unregister<QuranSessionsPlatformConfigStore>();
      }
    });

    Widget createTestableWidget(Widget child) {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => child,
          ),
          GoRoute(
            path: '/sessions',
            builder: (_, _) {
              navigatedPaths.add('/sessions');
              return const Scaffold(body: Text('Sessions Home'));
            },
          ),
          GoRoute(
            path: '/sessions/detail/:bookingId',
            builder: (context, state) {
              final bookingId = state.pathParameters['bookingId'];
              navigatedPaths.add('/sessions/detail/$bookingId');
              return Scaffold(body: Text('Detail $bookingId'));
            },
          ),
          GoRoute(
            path: '/quran-reader/:surahNumber',
            builder: (context, state) {
              final surahNumber = state.pathParameters['surahNumber'];
              final ayahNumber = state.uri.queryParameters['ayah-number'];
              navigatedPaths.add(
                '/quran-reader/$surahNumber?ayah-number=$ayahNumber',
              );
              return Scaffold(body: Text('Quran Reader $surahNumber'));
            },
          ),
        ],
      );

      return BlocProvider<HomeLearningCubit>.value(
        value: cubit,
        child: MaterialApp.router(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          ),
          locale: const Locale('en'),
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            QuranSessionsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
    }

    testWidgets('HomeLearningInterestCard renders and reacts to buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(const HomeLearningInterestCard()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learn Quran with a Qualified Tutor?'), findsOneWidget);
      expect(
        find.text(
          'Master your recitation and Tajweed 1-on-1 with live feedback.',
        ),
        findsOneWidget,
      );

      // Tap Yes, interested
      await tester.tap(find.text('Yes, interested'));
      await tester.pumpAndSettle();

      expect(preferenceStore.hasSetInterest, isTrue);
      expect(preferenceStore.isInterested, isTrue);
      expect(navigatedPaths, contains('/sessions'));
    });

    testWidgets(
      'HomeLearningInterestCard tapping Not now updates preferences',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(const HomeLearningInterestCard()),
        );
        await tester.pumpAndSettle();

        // Tap Not now
        await tester.tap(find.text('Not now'));
        await tester.pumpAndSettle();

        expect(preferenceStore.hasSetInterest, isTrue);
        expect(preferenceStore.isInterested, isFalse);
        expect(navigatedPaths, isEmpty);
      },
    );

    testWidgets(
      'HomeLearningBrowseCard renders and routes to Learn Quran home',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(const HomeLearningBrowseCard()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Learn Quran'), findsOneWidget);
        expect(
          find.text('Choose your hafiz and book a live 1-on-1 session.'),
          findsOneWidget,
        );

        await tester.tap(find.text('Start learning'));
        await tester.pumpAndSettle();

        expect(navigatedPaths, contains('/sessions'));
      },
    );

    testWidgets(
      'HomeLearningNextSessionCard renders imminent countdown and navigates',
      (tester) async {
        final session = QuranSession(
          id: 'session_next',
          bookingId: 'booking_123',
          teacherId: 'teacher_1',
          studentId: 'student_123',
          startsAt: testNow.add(const Duration(minutes: 45)),
          endsAt: testNow.add(const Duration(hours: 1, minutes: 15)),
          callType: SessionCallType.videoCall,
          status: QuranSessionStatus.scheduled,
        );

        await tester.pumpWidget(
          createTestableWidget(
            HomeLearningNextSessionCard(
              session: session,
              nowResolver: () => testNow,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Next Quran Session'), findsOneWidget);
        expect(find.text('Starts in 45m'), findsOneWidget);
        expect(
          find.text('الشيخ عبدالله الأحمدي'),
          findsOneWidget,
        ); // Resolved from MVP store

        // Tap Join Video Session
        await tester.tap(find.text('Join now'));
        await tester.pumpAndSettle();

        expect(navigatedPaths, contains('/sessions/detail/booking_123'));
      },
    );

    testWidgets('HomeLearningNextSessionCard renders live indicator', (
      tester,
    ) async {
      final session = QuranSession(
        id: 'session_live',
        bookingId: 'booking_123',
        teacherId: 'teacher_2',
        studentId: 'student_123',
        startsAt: testNow.subtract(const Duration(minutes: 10)),
        endsAt: testNow.add(const Duration(minutes: 20)),
        callType: SessionCallType.videoCall,
        status: QuranSessionStatus.scheduled,
      );

      await tester.pumpWidget(
        createTestableWidget(
          HomeLearningNextSessionCard(
            session: session,
            nowResolver: () => testNow,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live now'), findsOneWidget);
      expect(find.text('أ. فاطمة النووي'), findsOneWidget);
    });

    testWidgets(
      'HomeLearningPendingBookingCard renders approval state and reacts',
      (tester) async {
        final session = QuranSession(
          id: 'session_pending',
          bookingId: 'booking_pending',
          teacherId: 'teacher_3',
          studentId: 'student_123',
          startsAt: testNow.add(const Duration(hours: 5)),
          endsAt: testNow.add(const Duration(hours: 5, minutes: 30)),
          callType: SessionCallType.videoCall,
          status: QuranSessionStatus.scheduled,
          lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
        );

        await tester.pumpWidget(
          createTestableWidget(
            HomeLearningPendingBookingCard(session: session),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pending Tutor Booking'), findsOneWidget);
        expect(find.text('Awaiting tutor approval'), findsOneWidget);
        expect(find.text('الشيخ ماهر الزياد'), findsOneWidget);

        // Tap View Details
        await tester.tap(find.text('View details'));
        await tester.pumpAndSettle();

        expect(navigatedPaths, contains('/sessions/detail/booking_pending'));
      },
    );

    testWidgets('HomeLearningRevisionCard renders and practice triggers action', (
      tester,
    ) async {
      final revisionAggregate = SessionAggregate(
        id: 'booking_past',
        teacherId: 'teacher_1',
        studentId: 'student_123',
        slotId: 'slot_1',
        startsAt: testNow.subtract(const Duration(days: 3)),
        pricingType: SessionPricingType.free,
        lifecycleStatus: SessionLifecycleStatus.completed,
        createdAt: testNow.subtract(const Duration(days: 3)),
        updatedAt: testNow.subtract(const Duration(days: 3)),
        revisionSurahNumber: 18, // Al-Kahf
        revisionAyahNumber: 1,
      );

      await tester.pumpWidget(
        createTestableWidget(
          HomeLearningRevisionCard(revisionAggregate: revisionAggregate),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue Learning'), findsOneWidget);
      // "Practice Surah 18..." is from intl_en: sessionRevisionPracticeBody
      expect(
        find.text(
          'Practice Surah 18 in Tilawa\'s Quran reader before or after your session.',
        ),
        findsOneWidget,
      );

      // Tap Practice
      await tester.tap(find.text('Practice in Quran reader'));
      await tester.pumpAndSettle();

      expect(preferenceStore.lastPracticedSessionId, 'booking_past');
      expect(navigatedPaths, contains('/quran-reader/18?ayah-number=1'));
    });
  });
}
