import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_sessions/quran_sessions.dart';
import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/lifecycle_test_helpers.dart';
import '../../helpers/fixtures.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  late FakeSessionRepository sessionRepo;
  late FakeScheduleRepository scheduleRepo;
  late FakeAvailabilityProvider availabilityProvider;
  late BlockGeneratedSlotUseCase blockGeneratedSlot;
  late SpyGetTeacherAvailabilityUseCase spyGetAvailability;
  late TeacherDashboardBloc bloc;

  final fixedNow = DateTime.utc(2026, 1, 9);

  setUpAll(tz_data.initializeTimeZones);

  setUp(() {
    sessionRepo = FakeSessionRepository();
    scheduleRepo = FakeScheduleRepository();
    availabilityProvider = FakeAvailabilityProvider();
    blockGeneratedSlot = BlockGeneratedSlotUseCase(scheduleRepo);
    spyGetAvailability = SpyGetTeacherAvailabilityUseCase(
      scheduleRepository: scheduleRepo,
      sessionRepository: sessionRepo,
      now: () => fixedNow,
    );
    bloc = TeacherDashboardBloc(
      getTeacherSessions: GetTeacherSessionsUseCase(sessionRepo),
      getAvailability: spyGetAvailability,
      blockGeneratedSlot: blockGeneratedSlot,
      availabilityProvider: availabilityProvider,
      cancelSession: buildCancelSessionViaServerUseCase(),
      completeSession: buildCompleteSessionViaServerUseCase(),
      teacherId: 'teacher_1',
    );
  });

  tearDown(() => bloc.close());

  group('TeacherDashboardBloc', () {
    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'emits [Loading, Empty] when no sessions or generated slots',
      build: () => bloc,
      act: (b) => b.add(
        const TeacherDashboardLoadRequested(teacherId: 'teacher_1'),
      ),
      expect: () => [
        isA<TeacherDashboardLoading>(),
        isA<TeacherDashboardEmpty>(),
      ],
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'emits [Loading, Success] when sessions and generated slots are present',
      build: () {
        sessionRepo.sessions = [
          makeSession(
            teacherId: 'teacher_1',
            studentId: 'student_1',
            startsAt: DateTime.now().add(const Duration(hours: 2)),
          ),
        ];
        scheduleRepo.schedule = makeWeeklySchedule();
        return bloc;
      },
      act: (b) => b.add(
        const TeacherDashboardLoadRequested(teacherId: 'teacher_1'),
      ),
      expect: () => [
        isA<TeacherDashboardLoading>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(state.upcomingSessions).length.equals(1);
        check(state.availability).isNotEmpty();
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'emits [Loading, Failure] on session repository error',
      build: () {
        sessionRepo.failWith = const NetworkFailure();
        return bloc;
      },
      act: (b) => b.add(
        const TeacherDashboardLoadRequested(teacherId: 'teacher_1'),
      ),
      expect: () => [
        isA<TeacherDashboardLoading>(),
        isA<TeacherDashboardFailure>(),
      ],
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'AvailabilitySlotAdded appends slot to availability list',
      build: () => bloc,
      seed: () => TeacherDashboardSuccess(
        upcomingSessions: const [],
        availability: const [],
      ),
      act: (b) => b.add(AvailabilitySlotAdded(slot: makeSlot())),
      expect: () => [
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(state.availability).length.equals(1);
        check(state.isUpdatingAvailability).isFalse();
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'AvailabilitySlotRemoved blocks generated slot without refetch',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule();
        return bloc;
      },
      seed: () => TeacherDashboardSuccess(
        upcomingSessions: const [],
        availability: [
          TeacherAvailability(
            slotId: GeneratedSlot.deterministicId(
              'teacher_1',
              DateTime.utc(2026, 1, 10, 7, 0),
            ),
            teacherId: 'teacher_1',
            startsAt: DateTime.utc(2026, 1, 10, 7, 0),
            endsAt: DateTime.utc(2026, 1, 10, 7, 30),
            isBooked: false,
          ),
        ],
      ),
      act: (b) => b.add(
        AvailabilitySlotRemoved(
          teacherId: 'teacher_1',
          slot: TeacherAvailability(
            slotId: GeneratedSlot.deterministicId(
              'teacher_1',
              DateTime.utc(2026, 1, 10, 7, 0),
            ),
            teacherId: 'teacher_1',
            startsAt: DateTime.utc(2026, 1, 10, 7, 0),
            endsAt: DateTime.utc(2026, 1, 10, 7, 30),
            isBooked: false,
          ),
        ),
      ),
      expect: () => [
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(spyGetAvailability.callCount).equals(0);
        check(scheduleRepo.overrides).length.equals(1);
        check(state.availability).isEmpty();
        check(state.deletingSlotIds).isEmpty();
        check(state.slotDeleteSucceeded).isTrue();
        check(state.slotFailure).isNull();
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'AvailabilitySlotRemoved removes legacy slot via provider',
      build: () {
        availabilityProvider.published.addAll([
          makeSlot(slotId: 'slot_1'),
          makeSlot(slotId: 'slot_2'),
        ]);
        return bloc;
      },
      seed: () => TeacherDashboardSuccess(
        upcomingSessions: const [],
        availability: [
          makeSlot(slotId: 'slot_1'),
          makeSlot(slotId: 'slot_2'),
        ],
      ),
      act: (b) => b.add(
        AvailabilitySlotRemoved(
          teacherId: 'teacher_1',
          slot: makeSlot(slotId: 'slot_1'),
        ),
      ),
      expect: () => [
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(state.availability).length.equals(1);
        check(state.availability.first.slotId).equals('slot_2');
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'AvailabilitySlotRemoved on last window day drops slot and updates count',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule();
        return bloc;
      },
      act: (b) async {
        b.add(const TeacherDashboardLoadRequested(teacherId: 'teacher_1'));
        await b.stream.firstWhere((s) => s is TeacherDashboardSuccess);
        final before = b.state as TeacherDashboardSuccess;
        final countBefore = before.availability.length;
        final days =
            before.availability
                .map((s) {
                  final local = s.startsAt.toLocal();
                  return DateTime(local.year, local.month, local.day);
                })
                .toSet()
                .toList()
              ..sort();
        final lastDay = days.last;
        final target = before.availability.firstWhere((s) {
          final local = s.startsAt.toLocal();
          return DateTime(local.year, local.month, local.day) == lastDay;
        });
        b.add(
          AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: target),
        );
        await b.stream.firstWhere((s) {
          if (s is! TeacherDashboardSuccess) return false;
          return s.deletingSlotIds.isEmpty && s.slotDeleteSucceeded;
        });
        final after = b.state as TeacherDashboardSuccess;
        check(after.availability.length).equals(countBefore - 1);
        check(
          after.availability.any((s) => s.slotId == target.slotId),
        ).isFalse();
      },
      expect: () => [
        isA<TeacherDashboardLoading>(),
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(scheduleRepo.overrides).isNotEmpty();
        check(state.slotFailure).isNull();
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'AvailabilitySlotRemoved on middle day does not remove other days',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule(
          rules: {
            Weekday.saturday: const [
              TimeRange(start: LocalTime(9, 0), end: LocalTime(12, 0)),
            ],
            Weekday.sunday: const [
              TimeRange(start: LocalTime(9, 0), end: LocalTime(12, 0)),
            ],
          },
        );
        return bloc;
      },
      act: (b) async {
        b.add(const TeacherDashboardLoadRequested(teacherId: 'teacher_1'));
        await b.stream.firstWhere((s) => s is TeacherDashboardSuccess);
        final before = b.state as TeacherDashboardSuccess;
        final saturdaySlot = before.availability.firstWhere(
          (s) => s.startsAt.toUtc().weekday == DateTime.saturday,
        );
        b.add(
          AvailabilitySlotRemoved(
            teacherId: 'teacher_1',
            slot: saturdaySlot,
          ),
        );
        await b.stream.firstWhere((s) {
          if (s is! TeacherDashboardSuccess) return false;
          return s.deletingSlotIds.isEmpty && s.slotDeleteSucceeded;
        });
      },
      expect: () => [
        isA<TeacherDashboardLoading>(),
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (b) {
        final after = b.state as TeacherDashboardSuccess;
        check(
          after.availability.any(
            (s) => s.startsAt.toUtc().weekday == DateTime.sunday,
          ),
        ).isTrue();
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'AvailabilitySlotRemoved blocks booked legacy slot',
      build: () {
        availabilityProvider.published.add(
          makeSlot(slotId: 'booked_slot', isBooked: true),
        );
        return bloc;
      },
      seed: () => TeacherDashboardSuccess(
        upcomingSessions: const [],
        availability: [makeSlot(slotId: 'booked_slot', isBooked: true)],
      ),
      act: (b) => b.add(
        AvailabilitySlotRemoved(
          teacherId: 'teacher_1',
          slot: makeSlot(slotId: 'booked_slot', isBooked: true),
        ),
      ),
      expect: () => [isA<TeacherDashboardSuccess>()],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(state.availability).length.equals(1);
        check(state.slotFailure).isA<SlotUnavailableFailure>();
        check(availabilityProvider.withdrawn).isEmpty();
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'AvailabilitySlotRemoved on generated failure keeps slot',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule();
        scheduleRepo.failWith = const NetworkFailure();
        return bloc;
      },
      seed: () => TeacherDashboardSuccess(
        upcomingSessions: const [],
        availability: [
          TeacherAvailability(
            slotId: GeneratedSlot.deterministicId(
              'teacher_1',
              DateTime.utc(2026, 1, 10, 7, 0),
            ),
            teacherId: 'teacher_1',
            startsAt: DateTime.utc(2026, 1, 10, 7, 0),
            endsAt: DateTime.utc(2026, 1, 10, 7, 30),
            isBooked: false,
          ),
        ],
      ),
      act: (b) => b.add(
        AvailabilitySlotRemoved(
          teacherId: 'teacher_1',
          slot: TeacherAvailability(
            slotId: GeneratedSlot.deterministicId(
              'teacher_1',
              DateTime.utc(2026, 1, 10, 7, 0),
            ),
            teacherId: 'teacher_1',
            startsAt: DateTime.utc(2026, 1, 10, 7, 0),
            endsAt: DateTime.utc(2026, 1, 10, 7, 30),
            isBooked: false,
          ),
        ),
      ),
      expect: () => [
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(spyGetAvailability.callCount).equals(0);
        check(state.availability).length.equals(1);
        check(state.slotFailure).isA<NetworkFailure>();
        check(state.slotDeleteSucceeded).isFalse();
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'AvailabilitySlotRemoved ignores duplicate delete for same slot',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule();
        return bloc;
      },
      seed: () {
        final slot = TeacherAvailability(
          slotId: GeneratedSlot.deterministicId(
            'teacher_1',
            DateTime.utc(2026, 1, 10, 7, 0),
          ),
          teacherId: 'teacher_1',
          startsAt: DateTime.utc(2026, 1, 10, 7, 0),
          endsAt: DateTime.utc(2026, 1, 10, 7, 30),
          isBooked: false,
        );
        return TeacherDashboardSuccess(
          upcomingSessions: const [],
          availability: [slot],
          deletingSlotIds: {slot.slotId},
        );
      },
      act: (b) => b.add(
        AvailabilitySlotRemoved(
          teacherId: 'teacher_1',
          slot: TeacherAvailability(
            slotId: GeneratedSlot.deterministicId(
              'teacher_1',
              DateTime.utc(2026, 1, 10, 7, 0),
            ),
            teacherId: 'teacher_1',
            startsAt: DateTime.utc(2026, 1, 10, 7, 0),
            endsAt: DateTime.utc(2026, 1, 10, 7, 30),
            isBooked: false,
          ),
        ),
      ),
      expect: () => <TeacherDashboardState>[],
      verify: (_) {
        check(scheduleRepo.getOverrideByDateCallCount).equals(0);
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'AvailabilitySlotRemoved blocks booked generated slot',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule();
        return bloc;
      },
      seed: () => TeacherDashboardSuccess(
        upcomingSessions: const [],
        availability: [
          TeacherAvailability(
            slotId: GeneratedSlot.deterministicId(
              'teacher_1',
              DateTime.utc(2026, 1, 10, 7, 0),
            ),
            teacherId: 'teacher_1',
            startsAt: DateTime.utc(2026, 1, 10, 7, 0),
            endsAt: DateTime.utc(2026, 1, 10, 7, 30),
            isBooked: true,
          ),
        ],
      ),
      act: (b) => b.add(
        AvailabilitySlotRemoved(
          teacherId: 'teacher_1',
          slot: TeacherAvailability(
            slotId: GeneratedSlot.deterministicId(
              'teacher_1',
              DateTime.utc(2026, 1, 10, 7, 0),
            ),
            teacherId: 'teacher_1',
            startsAt: DateTime.utc(2026, 1, 10, 7, 0),
            endsAt: DateTime.utc(2026, 1, 10, 7, 30),
            isBooked: true,
          ),
        ),
      ),
      expect: () => [isA<TeacherDashboardSuccess>()],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(state.availability).length.equals(1);
        check(state.slotFailure).isA<SlotUnavailableFailure>();
        check(scheduleRepo.getOverrideByDateCallCount).equals(0);
      },
    );
  });
}
