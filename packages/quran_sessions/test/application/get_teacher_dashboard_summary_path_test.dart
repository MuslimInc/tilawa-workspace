import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../helpers/availability_test_helpers.dart';
import '../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../helpers/fakes/fake_session_repository.dart';
import '../helpers/fakes/fake_teacher_profile_repository.dart';
import '../helpers/fakes/fake_user_profile_repository.dart';
import '../helpers/fixtures.dart';

class _FakeSummarySource implements TeacherDashboardSummarySource {
  Either<QuranSessionsFailure, TeacherDashboardSummary?> result = const Right(
    null,
  );
  bool throwOnFetch = false;
  int fetchCount = 0;

  @override
  Future<Either<QuranSessionsFailure, TeacherDashboardSummary?>> fetch(
    String teacherProfileId,
  ) async {
    fetchCount++;
    if (throwOnFetch) throw StateError('boom');
    return result;
  }
}

void main() {
  setUpAll(tz_data.initializeTimeZones);

  // FakeSessionRepository filters by the real clock, so anchor the fixture
  // in the future: the next Saturday 06:00 UTC (= 09:00 Asia/Riyadh, a
  // DST-free zone) at least one day ahead — the first generated slot start.
  final bookedStart = () {
    final realNow = DateTime.now().toUtc();
    var day = DateTime.utc(realNow.year, realNow.month, realNow.day, 6);
    while (day.weekday != DateTime.saturday ||
        day.isBefore(realNow.add(const Duration(days: 1)))) {
      day = day.add(const Duration(days: 1));
    }
    return day;
  }();
  // The reference instant handed to the use case: two days before the slot.
  final now = bookedStart.subtract(const Duration(days: 2));

  late FakeSessionRepository sessions;
  late FakeScheduleRepository schedules;
  late FakeMarketSchedulingConfigRepository config;
  late FakeUserProfileRepository users;
  late FakeTeacherProfileRepository teacherProfiles;
  late FakeBookedSlotLockRepository locks;
  late _FakeSummarySource summarySource;

  GetTeacherDashboardUseCase buildUseCase({
    TeacherDashboardSummarySource? source,
  }) {
    return GetTeacherDashboardUseCase(
      summarySource: source,
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
      cacheStore: MemoryCacheStore(),
      currentTime: () => now,
    );
  }

  List<QuranSession> makeDashboardSessions() => [
    makeSession(
      id: 'upcoming_1',
      teacherId: 'teacher_profile_1',
      startsAt: bookedStart,
      endsAt: bookedStart.add(const Duration(minutes: 30)),
    ),
    makeSession(
      id: 'pending_1',
      teacherId: 'teacher_profile_1',
      lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
      startsAt: bookedStart.add(const Duration(days: 1)),
      endsAt: bookedStart.add(const Duration(days: 1, minutes: 30)),
    ),
  ];

  TeacherDashboardSummary makeSummary({
    bool truncated = false,
    bool includeSchedule = true,
    DateTime? updatedAt,
    List<QuranSession>? sessionList,
  }) {
    return TeacherDashboardSummary(
      teacherProfileId: 'teacher_profile_1',
      ownerUserId: 'teacher_user_1',
      displayName: 'Ustadh Test',
      countryCode: 'EG',
      schedulingConfig: MarketSchedulingConfig.defaults,
      weeklySchedule: includeSchedule
          ? makeWeeklySchedule(
              teacherId: 'teacher_profile_1',
              timezone: 'Asia/Riyadh',
            )
          : null,
      overrides: const [],
      sessions: sessionList ?? makeDashboardSessions(),
      sessionsTruncated: truncated,
      updatedAt: updatedAt ?? now.subtract(const Duration(hours: 1)),
    );
  }

  setUp(() {
    sessions = FakeSessionRepository()..sessions = makeDashboardSessions();
    schedules = FakeScheduleRepository()
      ..schedule = makeWeeklySchedule(
        teacherId: 'teacher_profile_1',
        timezone: 'Asia/Riyadh',
      );
    config = FakeMarketSchedulingConfigRepository();
    users = FakeUserProfileRepository(
      profile: makeProfile(
        userId: 'teacher_user_1',
        role: UserRole.student,
        countryCode: 'EG',
      ),
    );
    teacherProfiles = FakeTeacherProfileRepository(
      profile: makeTeacherProfile(
        id: 'teacher_profile_1',
        userId: 'teacher_user_1',
      ),
    );
    // Legacy booked starts come from the lock repo; mirror the sessions the
    // summary path derives its starts from, so both paths see the same data.
    locks = FakeBookedSlotLockRepository();
    for (final session in makeDashboardSessions()) {
      locks.seedHardLock(
        teacherId: 'teacher_profile_1',
        startUtc: session.startsAt.toUtc(),
      );
    }
    summarySource = _FakeSummarySource();
  });

  TeacherDashboardResult rightOf(
    Either<QuranSessionsFailure, TeacherDashboardResult> either,
  ) {
    check(either.isRight()).isTrue();
    return either.fold((f) => throw StateError('unexpected $f'), (r) => r);
  }

  group('summary path', () {
    test(
      'fresh summary serves the dashboard without any legacy reads',
      () async {
        summarySource.result = Right(makeSummary());
        final useCase = buildUseCase(source: summarySource);

        final result = rightOf(
          await useCase(teacherProfileId: 'teacher_profile_1', now: now),
        );

        check(summarySource.fetchCount).equals(1);
        check(schedules.getScheduleCallCount).equals(0);
        check(sessions.getTeacherUpcomingSessionsCallCount).equals(0);
        check(teacherProfiles.getProfileByIdCallCount).equals(0);
        check(users.getProfileCallCount).equals(0);

        check(result.profile.countryCode).equals('EG');
        check(
          result.pendingBookingRequests.map((s) => s.id),
        ).deepEquals(['pending_1']);
        check(result.upcomingSessions.map((s) => s.id)).deepEquals([
          'upcoming_1',
        ]);
        check(result.schedule).isNotNull();
      },
    );

    test(
      'summary and legacy paths produce identical dashboard content',
      () async {
        summarySource.result = Right(makeSummary());
        final summaryResult = rightOf(
          await buildUseCase(source: summarySource)(
            teacherProfileId: 'teacher_profile_1',
            now: now,
          ),
        );
        final legacyResult = rightOf(
          await buildUseCase(source: null)(
            teacherProfileId: 'teacher_profile_1',
            now: now,
          ),
        );

        check(
          summaryResult.pendingBookingRequests.map((s) => s.id).toList(),
        ).deepEquals(
          legacyResult.pendingBookingRequests.map((s) => s.id).toList(),
        );
        check(
          summaryResult.upcomingSessions.map((s) => s.id).toList(),
        ).deepEquals(legacyResult.upcomingSessions.map((s) => s.id).toList());
        check(
          summaryResult.availability.map((a) => a.slotId).toList(),
        ).deepEquals(legacyResult.availability.map((a) => a.slotId).toList());
        check(summaryResult.availability).isNotEmpty();
        check(summaryResult.schedulingConfig).equals(
          legacyResult.schedulingConfig,
        );
        check(summaryResult.schedule).equals(legacyResult.schedule);
        check(summaryResult.profile.countryCode).equals(
          legacyResult.profile.countryCode,
        );
        // The booked session start must be excluded from generated slots on
        // both paths.
        check(
          summaryResult.availability.map((a) => a.startsAt.toUtc()),
        ).not((it) => it.contains(bookedStart));
      },
    );

    test('summary with no schedule yields empty availability', () async {
      summarySource.result = Right(makeSummary(includeSchedule: false));
      final useCase = buildUseCase(source: summarySource);

      final result = rightOf(
        await useCase(teacherProfileId: 'teacher_profile_1', now: now),
      );

      check(result.availability).isEmpty();
      check(result.schedule).isNull();
      check(schedules.getScheduleCallCount).equals(0);
    });
  });

  group('legacy fallback', () {
    Future<void> expectLegacyPathServed(
      GetTeacherDashboardUseCase useCase,
    ) async {
      final result = rightOf(
        await useCase(teacherProfileId: 'teacher_profile_1', now: now),
      );
      // Legacy reads happened and produced the full dashboard.
      check(schedules.getScheduleCallCount).equals(1);
      check(sessions.getTeacherUpcomingSessionsCallCount).equals(1);
      check(result.upcomingSessions.map((s) => s.id)).deepEquals([
        'upcoming_1',
      ]);
      check(
        result.pendingBookingRequests.map((s) => s.id),
      ).deepEquals(['pending_1']);
    }

    test('missing summary doc falls back to legacy reads', () async {
      summarySource.result = const Right(null);
      await expectLegacyPathServed(buildUseCase(source: summarySource));
      check(summarySource.fetchCount).equals(1);
    });

    test('truncated summary falls back to legacy reads', () async {
      summarySource.result = Right(makeSummary(truncated: true));
      await expectLegacyPathServed(buildUseCase(source: summarySource));
    });

    test('stale summary falls back to legacy reads', () async {
      summarySource.result = Right(
        makeSummary(updatedAt: now.subtract(const Duration(hours: 27))),
      );
      await expectLegacyPathServed(buildUseCase(source: summarySource));
    });

    test(
      'summary fetch failure falls back instead of failing the dashboard',
      () async {
        summarySource.result = const Left(NetworkFailure());
        await expectLegacyPathServed(buildUseCase(source: summarySource));
      },
    );

    test(
      'summary fetch throwing falls back instead of failing the dashboard',
      () async {
        summarySource.throwOnFetch = true;
        await expectLegacyPathServed(buildUseCase(source: summarySource));
      },
    );

    test('absent summary source keeps the pure legacy path', () async {
      await expectLegacyPathServed(buildUseCase(source: null));
    });
  });
}
