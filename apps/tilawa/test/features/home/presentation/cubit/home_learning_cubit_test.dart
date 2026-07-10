import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/home/presentation/cubit/home_learning_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_learning_state.dart';
import 'package:tilawa/features/home/presentation/services/home_learning_preference_store.dart';
import 'package:tilawa/features/quran_sessions/domain/entities/quran_sessions_platform_config.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_platform_config_store.dart';

class FakeAuthSessionProvider implements AuthSessionProvider {
  String? userId;
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
    if (result != null) return result!;
    return const Right(StudentSessionsPage(upcoming: [], past: []));
  }
}

class FakeGetSessionAggregateUseCase implements GetSessionAggregateUseCase {
  Either<QuranSessionsFailure, SessionAggregate>? result;

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> call(
    String bookingId,
  ) async {
    if (result != null) return result!;
    return const Left(ServerFailure(statusCode: 404));
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
  group('HomeLearningCubit', () {
    late FakeAuthSessionProvider fakeAuth;
    late FakeGetStudentSessionsUseCase getStudentSessions;
    late FakeGetSessionAggregateUseCase getSessionAggregate;
    late FakeHomeLearningPreferenceStore preferenceStore;
    late DateTime testNow;

    late QuranSessionsPlatformConfigStore configStore;

    setUp(() {
      configStore = QuranSessionsPlatformConfigStore();
      configStore.setConfig(
        const QuranSessionsPlatformConfig(
          quranSessionsEnabled: true,
          studentEntryEnabled: true,
          bookingEnabled: true,
          bookingMode: 'requiresTutorApproval',
          sessionMode: 'videoOnly',
          enabledCallProviders: {'external', 'mock'},
        ),
      );
      if (getIt.isRegistered<QuranSessionsPlatformConfigStore>()) {
        getIt.unregister<QuranSessionsPlatformConfigStore>();
      }
      getIt.registerSingleton<QuranSessionsPlatformConfigStore>(configStore);

      fakeAuth = FakeAuthSessionProvider()..userId = 'student_123';
      if (getIt.isRegistered<AuthSessionProvider>()) {
        getIt.unregister<AuthSessionProvider>();
      }
      getIt.registerSingleton<AuthSessionProvider>(fakeAuth);

      getStudentSessions = FakeGetStudentSessionsUseCase();
      getSessionAggregate = FakeGetSessionAggregateUseCase();
      preferenceStore = FakeHomeLearningPreferenceStore();
      testNow = DateTime(2026, 7, 10, 10, 0, 0); // Friday 10:00 AM
    });

    tearDown(() {
      if (getIt.isRegistered<AuthSessionProvider>()) {
        getIt.unregister<AuthSessionProvider>();
      }
      if (getIt.isRegistered<QuranSessionsPlatformConfigStore>()) {
        getIt.unregister<QuranSessionsPlatformConfigStore>();
      }
    });

    HomeLearningCubit createCubit() {
      return HomeLearningCubit(
        getStudentSessions: getStudentSessions,
        getSessionAggregate: getSessionAggregate,
        preferenceStore: preferenceStore,
      )..clock = () => testNow;
    }

    test('initial state is initial', () {
      final cubit = createCubit();
      expect(cubit.state.status, HomeLearningStatus.initial);
      cubit.close();
    });

    test('unauthenticated user emits none', () async {
      fakeAuth.userId = null;
      final cubit = createCubit();
      await cubit.load();
      expect(cubit.state.status, HomeLearningStatus.none);
      cubit.close();
    });

    test(
      'ongoing session startsAt <= now <= endsAt takes highest priority',
      () async {
        final session = QuranSession(
          id: 'session_1',
          bookingId: 'booking_1',
          teacherId: 'teacher_1',
          studentId: 'student_123',
          startsAt: testNow.subtract(const Duration(minutes: 15)),
          endsAt: testNow.add(const Duration(minutes: 30)),
          callType: SessionCallType.videoCall,
          status: QuranSessionStatus.scheduled,
        );

        getStudentSessions.result = Right(
          StudentSessionsPage(
            upcoming: [session],
            past: [],
          ),
        );

        final cubit = createCubit();
        await cubit.load();

        expect(cubit.state.status, HomeLearningStatus.nextSession);
        expect(cubit.state.session, session);
        cubit.close();
      },
    );

    test('imminent session within 2 hours takes next priority', () async {
      final imminent = QuranSession(
        id: 'session_2',
        bookingId: 'booking_2',
        teacherId: 'teacher_1',
        studentId: 'student_123',
        startsAt: testNow.add(const Duration(minutes: 45)), // In 45 mins
        endsAt: testNow.add(const Duration(hours: 1, minutes: 15)),
        callType: SessionCallType.videoCall,
        status: QuranSessionStatus.scheduled,
      );

      final farUpcoming = QuranSession(
        id: 'session_3',
        bookingId: 'booking_3',
        teacherId: 'teacher_1',
        studentId: 'student_123',
        startsAt: testNow.add(
          const Duration(hours: 3),
        ), // In 3 hours (far upcoming)
        endsAt: testNow.add(const Duration(hours: 3, minutes: 30)),
        callType: SessionCallType.videoCall,
        status: QuranSessionStatus.scheduled,
      );

      getStudentSessions.result = Right(
        StudentSessionsPage(
          upcoming: [farUpcoming, imminent],
          past: [],
        ),
      );

      final cubit = createCubit();
      await cubit.load();

      expect(cubit.state.status, HomeLearningStatus.nextSession);
      expect(cubit.state.session, imminent);
      cubit.close();
    });

    test('session exactly at 2-hour threshold is imminent', () async {
      final session = QuranSession(
        id: 'session_imminent',
        bookingId: 'booking_imminent',
        teacherId: 'teacher_1',
        studentId: 'student_123',
        startsAt: testNow.add(const Duration(hours: 2)), // Exactly 2h threshold
        endsAt: testNow.add(const Duration(hours: 2, minutes: 30)),
        callType: SessionCallType.videoCall,
        status: QuranSessionStatus.scheduled,
      );

      getStudentSessions.result = Right(
        StudentSessionsPage(
          upcoming: [session],
          past: [],
        ),
      );

      final cubit = createCubit();
      await cubit.load();

      expect(cubit.state.status, HomeLearningStatus.nextSession);
      cubit.close();
    });

    test('cancelled/rejected/inactive status sessions are ignored', () async {
      final cancelled = QuranSession(
        id: 'session_cancelled',
        bookingId: 'booking_cancelled',
        teacherId: 'teacher_1',
        studentId: 'student_123',
        startsAt: testNow.add(const Duration(minutes: 30)),
        endsAt: testNow.add(const Duration(hours: 1)),
        callType: SessionCallType.videoCall,
        status: QuranSessionStatus.cancelledByStudent, // Inactive status
      );

      getStudentSessions.result = Right(
        StudentSessionsPage(
          upcoming: [cancelled],
          past: [],
        ),
      );

      final cubit = createCubit();
      await cubit.load();

      expect(cubit.state.status, HomeLearningStatus.none);
      cubit.close();
    });

    test('pending booking is selected next', () async {
      final pendingApproval = QuranSession(
        id: 'session_pending',
        bookingId: 'booking_pending',
        teacherId: 'teacher_1',
        studentId: 'student_123',
        startsAt: testNow.add(const Duration(hours: 5)),
        endsAt: testNow.add(const Duration(hours: 5, minutes: 30)),
        callType: SessionCallType.videoCall,
        status: QuranSessionStatus.scheduled,
        lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
      );

      getStudentSessions.result = Right(
        StudentSessionsPage(
          upcoming: [],
          pending: [pendingApproval],
          past: [],
        ),
      );

      final cubit = createCubit();
      await cubit.load();

      expect(cubit.state.status, HomeLearningStatus.pendingBooking);
      expect(cubit.state.session, pendingApproval);
      cubit.close();
    });

    test(
      'revision practice from latest completed session within 7 days is next',
      () async {
        final pastSession = QuranSession(
          id: 'session_past',
          bookingId: 'booking_past',
          teacherId: 'teacher_1',
          studentId: 'student_123',
          startsAt: testNow.subtract(const Duration(days: 3)), // 3 days ago
          endsAt: testNow.subtract(
            const Duration(days: 2, hours: 23, minutes: 30),
          ),
          callType: SessionCallType.videoCall,
          status: QuranSessionStatus.completed,
          lifecycleStatus: SessionLifecycleStatus.completed,
        );

        final aggregate = SessionAggregate(
          id: 'booking_past',
          teacherId: 'teacher_1',
          studentId: 'student_123',
          slotId: 'slot_1',
          startsAt: pastSession.startsAt,
          pricingType: SessionPricingType.free,
          lifecycleStatus: SessionLifecycleStatus.completed,
          createdAt: pastSession.startsAt,
          updatedAt: pastSession.startsAt,
          revisionSurahNumber: 18, // Al-Kahf
          revisionAyahNumber: 1,
        );

        getStudentSessions.result = Right(
          StudentSessionsPage(
            upcoming: [],
            past: [pastSession],
          ),
        );

        getSessionAggregate.result = Right(aggregate);

        final cubit = createCubit();
        await cubit.load();

        expect(cubit.state.status, HomeLearningStatus.continueLearning);
        expect(cubit.state.revisionAggregate, aggregate);
        cubit.close();
      },
    );

    test('completed past session older than 7 days is ignored', () async {
      final oldPastSession = QuranSession(
        id: 'session_old',
        bookingId: 'booking_old',
        teacherId: 'teacher_1',
        studentId: 'student_123',
        startsAt: testNow.subtract(
          const Duration(days: 8),
        ), // 8 days ago (older than 7d)
        endsAt: testNow.subtract(
          const Duration(days: 7, hours: 23, minutes: 30),
        ),
        callType: SessionCallType.videoCall,
        status: QuranSessionStatus.completed,
        lifecycleStatus: SessionLifecycleStatus.completed,
      );

      getStudentSessions.result = Right(
        StudentSessionsPage(
          upcoming: [],
          past: [oldPastSession],
        ),
      );

      final cubit = createCubit();
      await cubit.load();

      expect(cubit.state.status, HomeLearningStatus.none);
      cubit.close();
    });

    test('revision already marked as practiced is ignored', () async {
      final pastSession = QuranSession(
        id: 'session_past',
        bookingId: 'booking_past',
        teacherId: 'teacher_1',
        studentId: 'student_123',
        startsAt: testNow.subtract(const Duration(days: 3)),
        endsAt: testNow.subtract(
          const Duration(days: 2, hours: 23, minutes: 30),
        ),
        callType: SessionCallType.videoCall,
        status: QuranSessionStatus.completed,
        lifecycleStatus: SessionLifecycleStatus.completed,
      );

      getStudentSessions.result = Right(
        StudentSessionsPage(
          upcoming: [],
          past: [pastSession],
        ),
      );

      preferenceStore.lastPracticedSessionId =
          'session_past'; // Marked as practiced

      final cubit = createCubit();
      await cubit.load();

      expect(cubit.state.status, HomeLearningStatus.none);
      cubit.close();
    });

    test(
      'interest signal is requested when not set and state is none',
      () async {
        getStudentSessions.result = const Right(
          StudentSessionsPage(
            upcoming: [],
            past: [],
          ),
        );

        preferenceStore.hasSetInterest = false; // Not set

        final cubit = createCubit();
        await cubit.load();

        expect(cubit.state.status, HomeLearningStatus.none);
        expect(cubit.state.isInterestSignalNeeded, isTrue);
        cubit.close();
      },
    );

    test(
      'interest signal is not requested and card stays hidden if user is not interested',
      () async {
        getStudentSessions.result = const Right(
          StudentSessionsPage(
            upcoming: [],
            past: [],
          ),
        );

        preferenceStore.hasSetInterest = true;
        preferenceStore.isInterested = false; // Not interested

        final cubit = createCubit();
        await cubit.load();

        expect(cubit.state.status, HomeLearningStatus.none);
        expect(cubit.state.isInterestSignalNeeded, isFalse);
        expect(cubit.state.isBrowseEntryVisible, isFalse);
        cubit.close();
      },
    );

    test(
      'interested user keeps the persistent browse entry on the fallback',
      () async {
        getStudentSessions.result = const Right(
          StudentSessionsPage(
            upcoming: [],
            past: [],
          ),
        );

        preferenceStore.hasSetInterest = true;
        preferenceStore.isInterested = true; // Said yes

        final cubit = createCubit();
        await cubit.load();

        expect(cubit.state.status, HomeLearningStatus.none);
        expect(cubit.state.isInterestSignalNeeded, isFalse);
        expect(cubit.state.isBrowseEntryVisible, isTrue);
        cubit.close();
      },
    );

    test(
      'answering yes swaps the prompt for the browse entry without a reload',
      () async {
        getStudentSessions.result = const Right(
          StudentSessionsPage(
            upcoming: [],
            past: [],
          ),
        );

        final cubit = createCubit();
        await cubit.load();
        expect(cubit.state.isInterestSignalNeeded, isTrue);

        await cubit.setTutoringInterest(isInterested: true);

        expect(cubit.state.isInterestSignalNeeded, isFalse);
        expect(cubit.state.isBrowseEntryVisible, isTrue);
        cubit.close();
      },
    );

    test(
      'answering not-now hides both the prompt and the browse entry',
      () async {
        getStudentSessions.result = const Right(
          StudentSessionsPage(
            upcoming: [],
            past: [],
          ),
        );

        final cubit = createCubit();
        await cubit.load();

        await cubit.setTutoringInterest(isInterested: false);

        expect(cubit.state.isInterestSignalNeeded, isFalse);
        expect(cubit.state.isBrowseEntryVisible, isFalse);
        cubit.close();
      },
    );

    test(
      'active learning states (ongoing/imminent) are shown even if user set isInterested=false',
      () async {
        final ongoingSession = QuranSession(
          id: 'session_1',
          bookingId: 'booking_1',
          teacherId: 'teacher_1',
          studentId: 'student_123',
          startsAt: testNow.subtract(const Duration(minutes: 15)),
          endsAt: testNow.add(const Duration(minutes: 30)),
          callType: SessionCallType.videoCall,
          status: QuranSessionStatus.scheduled,
        );

        getStudentSessions.result = Right(
          StudentSessionsPage(
            upcoming: [ongoingSession],
            past: [],
          ),
        );

        preferenceStore.hasSetInterest = true;
        preferenceStore.isInterested =
            false; // Not interested, but has active session!

        final cubit = createCubit();
        await cubit.load();

        expect(
          cubit.state.status,
          HomeLearningStatus.nextSession,
        ); // Should still show!
        cubit.close();
      },
    );

    test(
      'fails gracefully and falls back to none if session loading throws exception',
      () async {
        getStudentSessions.result = const Left(ServerFailure(statusCode: 500));

        final cubit = createCubit();
        await cubit.load();

        expect(cubit.state.status, HomeLearningStatus.none);
        cubit.close();
      },
    );
  });
}
