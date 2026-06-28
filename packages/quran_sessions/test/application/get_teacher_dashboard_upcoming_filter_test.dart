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
  group('GetTeacherDashboardUseCase upcoming filtering', () {
    late FakeSessionRepository sessions;
    late FakeScheduleRepository schedules;
    late FakeMarketSchedulingConfigRepository config;
    late FakeUserProfileRepository users;
    late FakeTeacherProfileRepository teacherProfiles;
    late FakeBookedSlotLockRepository locks;
    late GetTeacherDashboardUseCase useCase;

    final now = DateTime.utc(2026, 6, 27, 9);

    setUp(() {
      sessions = FakeSessionRepository();
      schedules = FakeScheduleRepository()
        ..schedule = makeWeeklySchedule(
          teacherId: 'teacher_profile_1',
          rules: const {},
        );
      config = FakeMarketSchedulingConfigRepository();
      users = FakeUserProfileRepository(
        profile: makeProfile(userId: 'teacher_user_1', role: UserRole.student),
      );
      teacherProfiles = FakeTeacherProfileRepository(
        profile: makeTeacherProfile(
          id: 'teacher_profile_1',
          userId: 'teacher_user_1',
        ),
      );
      locks = FakeBookedSlotLockRepository();
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
        cacheStore: MemoryCacheStore(),
        currentTime: () => now,
      );
    });

    test('excludes tutor-cancelled sessions from upcoming list', () async {
      sessions.sessions = [
        makeSession(
          id: 'active',
          teacherId: 'teacher_profile_1',
          lifecycleStatus: SessionLifecycleStatus.scheduled,
        ),
        makeSession(
          id: 'cancelled',
          teacherId: 'teacher_profile_1',
          lifecycleStatus: SessionLifecycleStatus.cancelledByTeacher,
        ),
      ];

      final result = await useCase(
        teacherProfileId: 'teacher_profile_1',
        now: now,
        forceRefresh: true,
      );

      final dashboard = result.fold((_) => null, (v) => v)!;
      check(dashboard.upcomingSessions.length).equals(1);
      check(dashboard.upcomingSessions.single.id).equals('active');
    });

    test(
      'maps tutor_cancelled raw status out of upcoming via parser',
      () async {
        sessions.sessions = [
          makeSession(
            id: 'legacy_cancelled',
            teacherId: 'teacher_profile_1',
            status: QuranSessionStatus.cancelledByTeacher,
            lifecycleStatus: SessionLifecycleStatus.cancelledByTeacher,
          ),
        ];

        final result = await useCase(
          teacherProfileId: 'teacher_profile_1',
          now: now,
          forceRefresh: true,
        );

        final dashboard = result.fold((_) => null, (v) => v)!;
        check(dashboard.upcomingSessions).isEmpty();
      },
    );

    test('empty upcoming when every session is cancelled', () async {
      sessions.sessions = [
        makeSession(
          id: 'c1',
          teacherId: 'teacher_profile_1',
          lifecycleStatus: SessionLifecycleStatus.cancelledByTeacher,
        ),
        makeSession(
          id: 'c2',
          teacherId: 'teacher_profile_1',
          lifecycleStatus: SessionLifecycleStatus.cancelledByStudent,
        ),
      ];

      final result = await useCase(
        teacherProfileId: 'teacher_profile_1',
        now: now,
        forceRefresh: true,
      );

      final dashboard = result.fold((_) => null, (v) => v)!;
      check(dashboard.upcomingSessions).isEmpty();
    });
  });
}
