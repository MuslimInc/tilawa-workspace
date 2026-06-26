import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../helpers/availability_test_helpers.dart';
import '../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../helpers/fakes/fake_session_repository.dart';
import '../helpers/fakes/fake_teacher_profile_repository.dart';
import '../helpers/fakes/fake_user_profile_repository.dart';
import '../helpers/fixtures.dart';

void main() {
  group('GetTeacherDashboardUseCase cache', () {
    late FakeSessionRepository sessions;
    late FakeScheduleRepository schedules;
    late FakeMarketSchedulingConfigRepository config;
    late FakeUserProfileRepository users;
    late FakeTeacherProfileRepository teacherProfiles;
    late FakeBookedSlotLockRepository locks;
    late MemoryCacheStore cache;
    late GetTeacherDashboardUseCase useCase;

    final now = DateTime.utc(2026, 6, 25, 9);

    setUp(() {
      sessions = FakeSessionRepository();
      schedules = FakeScheduleRepository()
        ..schedule = makeWeeklySchedule(
          teacherId: 'teacher_profile_1',
          rules: const {},
        );
      config = FakeMarketSchedulingConfigRepository();
      users = FakeUserProfileRepository(
        profile: makeProfile(
          userId: 'teacher_user_1',
          role: UserRole.student,
        ),
      );
      teacherProfiles = FakeTeacherProfileRepository(
        profile: makeTeacherProfile(
          id: 'teacher_profile_1',
          userId: 'teacher_user_1',
        ),
      );
      locks = FakeBookedSlotLockRepository();
      cache = MemoryCacheStore();
      useCase = GetTeacherDashboardUseCase(
        userProfileRepository: users,
        marketSchedulingConfigRepository: config,
        scheduleRepository: schedules,
        sessionRepository: sessions,
        teacherProfileRepository: teacherProfiles,
        getTeacherAvailability: buildGetTeacherAvailabilityUseCase(
          scheduleRepository: schedules,
          bookedSlotLockRepository: locks,
          now: () => now,
        ),
        cacheStore: cache,
        currentTime: () => now,
      );
    });

    test(
      'first load performs one scoped read per dashboard dependency',
      () async {
        final result = await useCase(
          teacherProfileId: 'teacher_profile_1',
          now: now,
        );

        check(result.isRight()).isTrue();
        check(teacherProfiles.getProfileByIdCallCount).equals(1);
        check(users.getProfileCallCount).equals(1);
        check(schedules.getScheduleCallCount).equals(2);
        check(sessions.getTeacherUpcomingSessionsCallCount).equals(1);
      },
    );

    test(
      'repeat load in same lifecycle reuses cached dashboard reads',
      () async {
        await useCase(teacherProfileId: 'teacher_profile_1', now: now);
        await useCase(teacherProfileId: 'teacher_profile_1', now: now);

        check(teacherProfiles.getProfileByIdCallCount).equals(1);
        check(users.getProfileCallCount).equals(1);
        check(schedules.getScheduleCallCount).equals(2);
        check(sessions.getTeacherUpcomingSessionsCallCount).equals(1);
      },
    );

    test('manual refresh bypasses cached dashboard reads once', () async {
      await useCase(teacherProfileId: 'teacher_profile_1', now: now);
      await useCase(
        teacherProfileId: 'teacher_profile_1',
        now: now,
        forceRefresh: true,
      );

      check(teacherProfiles.getProfileByIdCallCount).equals(2);
      check(schedules.getScheduleCallCount).equals(4);
      check(sessions.getTeacherUpcomingSessionsCallCount).equals(2);
    });

    test('failed read is not cached', () async {
      schedules.failWith = const NetworkFailure();

      final first = await useCase(
        teacherProfileId: 'teacher_profile_1',
        now: now,
      );
      schedules.failWith = null;
      final second = await useCase(
        teacherProfileId: 'teacher_profile_1',
        now: now,
      );

      check(first.isLeft()).isTrue();
      check(second.isRight()).isTrue();
      check(schedules.getScheduleCallCount).equals(3);
    });

    test(
      'falls back to global scheduling config when market has no override',
      () async {
        final egUsers = FakeUserProfileRepository(
          profile: makeProfile(
            userId: 'teacher_user_1',
            role: UserRole.student,
            countryCode: 'EG',
          ),
        );
        final egUseCase = GetTeacherDashboardUseCase(
          userProfileRepository: egUsers,
          marketSchedulingConfigRepository: config,
          scheduleRepository: schedules,
          sessionRepository: sessions,
          teacherProfileRepository: teacherProfiles,
          getTeacherAvailability: buildGetTeacherAvailabilityUseCase(
            scheduleRepository: schedules,
            bookedSlotLockRepository: locks,
            now: () => now,
          ),
          cacheStore: MemoryCacheStore(),
          currentTime: () => now,
        );

        final result = await egUseCase(
          teacherProfileId: 'teacher_profile_1',
          now: now,
        );

        check(result.isRight()).isTrue();
        // FakeMarketSchedulingConfigRepository returns Left(NotFoundFailure)
        // for 'EG' (no override registered), so the use case must fall back
        // to getGlobal(). Both calls increment the counter.
        check(config.getMarketSchedulingConfigCallCount).equals(2);
      },
    );
  });

  group('GetSessionDetailUseCase cache', () {
    test('fetches a session detail once while cache is fresh', () async {
      final sessions = FakeSessionRepository()
        ..sessions = [makeSession(id: 'session_1')];
      final useCase = GetSessionDetailUseCase(
        sessionRepository: sessions,
        cacheStore: MemoryCacheStore(),
      );

      await useCase('session_1');
      await useCase('session_1');

      check(sessions.getSessionByIdCallCount).equals(1);
    });
  });

  group('InvalidateQuranSessionCacheUseCase', () {
    test(
      'session mutation invalidates detail, dashboard, and student keys',
      () {
        final cache = MemoryCacheStore()
          ..put(
            SessionCacheKey.sessionDetail('session_1'),
            CacheEntry(makeSession(id: 'session_1'), DateTime.now()),
          )
          ..put(
            SessionCacheKey.teacherDashboardSessions('teacher_profile_1'),
            CacheEntry(<QuranSession>[], DateTime.now()),
          )
          ..put(
            SessionCacheKey.teacherAvailability('teacher_profile_1'),
            CacheEntry(<TeacherAvailability>[], DateTime.now()),
          )
          ..put(
            SessionCacheKey.studentSessions('student_1'),
            CacheEntry(<QuranSession>[], DateTime.now()),
          );

        InvalidateQuranSessionCacheUseCase(cache).invalidateSession(
          'session_1',
          teacherProfileId: 'teacher_profile_1',
          studentId: 'student_1',
        );

        check(
          cache.get<QuranSession>(SessionCacheKey.sessionDetail('session_1')),
        ).isNull();
        check(
          cache.get<List<QuranSession>>(
            SessionCacheKey.teacherDashboardSessions('teacher_profile_1'),
          ),
        ).isNull();
        check(
          cache.get<List<TeacherAvailability>>(
            SessionCacheKey.teacherAvailability('teacher_profile_1'),
          ),
        ).isNull();
        check(
          cache.get<List<QuranSession>>(
            SessionCacheKey.studentSessions('student_1'),
          ),
        ).isNull();
      },
    );
  });
}
