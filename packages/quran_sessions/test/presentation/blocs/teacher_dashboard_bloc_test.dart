import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_user_profile_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/lifecycle_test_helpers.dart';

/// Test double for [CommitTimerFactory] — fires callbacks on demand.
class FakeCommitTimers {
  final List<({Duration delay, void Function() onFire})> scheduled = [];
  int factoryCallCount = 0;
  int cancelCallCount = 0;

  CommitTimerFactory createFactory() {
    return (delay, onFire) {
      factoryCallCount++;
      scheduled.add((delay: delay, onFire: onFire));
      return () {
        cancelCallCount++;
        scheduled.removeWhere((e) => e.onFire == onFire);
      };
    };
  }

  void fireAll() {
    for (final entry in List.of(scheduled)) {
      entry.onFire();
    }
  }

  int get count => scheduled.length;
}

void main() {
  late FakeSessionRepository sessionRepo;
  late FakeScheduleRepository scheduleRepo;
  late FakeMarketSchedulingConfigRepository schedulingConfigRepo;
  late FakeUserProfileRepository userProfileRepo;
  late InMemoryFridayReviewReminderStore fridayReminderStore;
  late FakeAvailabilityProvider availabilityProvider;
  late BlockGeneratedSlotUseCase blockGeneratedSlot;
  late SpyGetTeacherAvailabilityUseCase spyGetAvailability;
  late FakeBookedSlotLockRepository bookedSlotLockRepo;
  late FakeCommitTimers fakeTimers;
  late CommitTimerFactory testCommitTimerFactory;

  final fixedNow = DateTime.utc(2026, 1, 9);

  TeacherDashboardBloc buildBloc({
    Duration commitDelay = const Duration(days: 365),
    Future<bool> Function()? isConnected,
  }) {
    return buildTestTeacherDashboardBloc(
      sessionRepo: sessionRepo,
      getAvailability: spyGetAvailability,
      blockGeneratedSlot: blockGeneratedSlot,
      availabilityProvider: availabilityProvider,
      cancelSession: buildCancelSessionViaServerUseCase(),
      completeSession: buildCompleteSessionViaServerUseCase(),
      scheduleRepo: scheduleRepo,
      schedulingConfigRepo: schedulingConfigRepo,
      userProfileRepo: userProfileRepo,
      bookedSlotLockRepository: bookedSlotLockRepo,
      fridayReminderStore: fridayReminderStore,
      commitTimerFactory: testCommitTimerFactory,
      commitDelay: commitDelay,
      now: () => fixedNow,
      isConnected: isConnected,
    );
  }

  setUpAll(tz_data.initializeTimeZones);

  setUp(() {
    sessionRepo = FakeSessionRepository();
    scheduleRepo = FakeScheduleRepository();
    schedulingConfigRepo = FakeMarketSchedulingConfigRepository();
    userProfileRepo = FakeUserProfileRepository();
    fridayReminderStore = InMemoryFridayReviewReminderStore();
    availabilityProvider = FakeAvailabilityProvider();
    bookedSlotLockRepo = FakeBookedSlotLockRepository();
    blockGeneratedSlot = BlockGeneratedSlotUseCase(scheduleRepo);
    spyGetAvailability = SpyGetTeacherAvailabilityUseCase(
      scheduleRepository: scheduleRepo,
      bookedSlotLocks: bookedSlotLockRepo,
      now: () => fixedNow,
    );
    fakeTimers = FakeCommitTimers();
    testCommitTimerFactory = fakeTimers.createFactory();
  });

  final defaultGeneratedStart = DateTime.utc(2026, 1, 10, 7, 0);

  TeacherAvailability generatedSlot({DateTime? start}) {
    final slotStart = start ?? defaultGeneratedStart;
    return TeacherAvailability(
      slotId: GeneratedSlot.deterministicId('teacher_1', slotStart),
      teacherId: 'teacher_1',
      startsAt: slotStart,
      endsAt: slotStart.add(const Duration(minutes: 30)),
      isBooked: false,
    );
  }

  List<TeacherAvailability> threeDistinctGeneratedSlots() => [
    generatedSlot(start: DateTime.utc(2026, 1, 10, 7, 0)),
    generatedSlot(start: DateTime.utc(2026, 1, 10, 7, 30)),
    generatedSlot(start: DateTime.utc(2026, 1, 10, 8, 0)),
  ];

  group('TeacherDashboardBloc', () {
    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'emits [Loading, Empty] when no sessions or generated slots',
      build: () => buildBloc(),
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
        return buildBloc();
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
        return buildBloc();
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
      'emits [Loading, Failure(NetworkFailure)] when offline before fetch',
      build: () => buildBloc(isConnected: () async => false),
      act: (b) => b.add(
        const TeacherDashboardLoadRequested(teacherId: 'teacher_1'),
      ),
      expect: () => [
        isA<TeacherDashboardLoading>(),
        isA<TeacherDashboardFailure>().having(
          (s) => s.failure,
          'failure',
          isA<NetworkFailure>(),
        ),
      ],
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'ongoing session (started, not ended) appears in upcomingSessions',
      build: () {
        // Started 10 min ago, ends 20 min from now → ongoing.
        final start = DateTime.now().subtract(const Duration(minutes: 10));
        sessionRepo.sessions = [
          makeSession(
            id: 'ongoing',
            teacherId: 'teacher_1',
            studentId: 'student_1',
            startsAt: start,
            endsAt: start.add(const Duration(minutes: 30)),
          ),
        ];
        scheduleRepo.schedule = makeWeeklySchedule();
        return buildBloc();
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
        check(state.upcomingSessions.first.id).equals('ongoing');
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'AvailabilitySlotAdded appends slot to availability list',
      build: () => buildBloc(),
      seed: () => seedTeacherDashboardSuccess(
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

    test('remove does not commit before timer fires', () async {
      scheduleRepo.schedule = makeWeeklySchedule();
      final slot = generatedSlot();
      final testBloc = buildBloc();
      testBloc.emit(
        seedTeacherDashboardSuccess(
          upcomingSessions: const [],
          availability: [slot],
        ),
      );
      testBloc.add(
        AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slot),
      );
      await Future<void>.delayed(Duration.zero);
      check(fakeTimers.factoryCallCount).equals(1);
      check(scheduleRepo.overrides).isEmpty();
      fakeTimers.fireAll();
      await Future<void>.delayed(Duration.zero);
      check(scheduleRepo.overrides).isNotEmpty();
      await testBloc.close();
    });

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'optimistic remove drops slot before deferred commit',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule();
        return buildBloc();
      },
      seed: () {
        final slot = generatedSlot();
        return seedTeacherDashboardSuccess(
          upcomingSessions: const [],
          availability: [slot],
        );
      },
      act: (b) => b.add(
        AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: generatedSlot()),
      ),
      expect: () => [isA<TeacherDashboardSuccess>()],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(state.availability).isEmpty();
        check(state.pendingDeletes).length.equals(1);
        check(state.undoableSlotId).isNotNull();
        check(spyGetAvailability.callCount).equals(0);
        check(fakeTimers.factoryCallCount).equals(1);
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'deferred commit blocks generated slot when timer fires',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule();
        return buildBloc();
      },
      seed: () {
        final slot = generatedSlot();
        return seedTeacherDashboardSuccess(
          upcomingSessions: const [],
          availability: [slot],
        );
      },
      act: (b) async {
        b.add(
          AvailabilitySlotRemoved(
            teacherId: 'teacher_1',
            slot: generatedSlot(),
          ),
        );
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.availability.isEmpty;
        });
        fakeTimers.fireAll();
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.pendingDeletes.isEmpty;
        });
      },
      expect: () => [
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(scheduleRepo.overrides).length.equals(1);
        check(state.availability).isEmpty();
        check(state.pendingDeletes).isEmpty();
        check(spyGetAvailability.callCount).equals(0);
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'undo restores slot and cancels deferred commit',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule();
        return buildBloc();
      },
      seed: () {
        final slot = generatedSlot();
        return seedTeacherDashboardSuccess(
          upcomingSessions: const [],
          availability: [slot],
        );
      },
      act: (b) async {
        final slot = generatedSlot();
        b.add(AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slot));
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.availability.isEmpty;
        });
        b.add(AvailabilitySlotDeleteUndone(slotId: slot.slotId));
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.availability.isNotEmpty;
        });
        fakeTimers.fireAll();
      },
      expect: () => [
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(state.availability).length.equals(1);
        check(state.pendingDeletes).isEmpty();
        check(state.undoableSlotId).isNull();
        check(scheduleRepo.overrides).isEmpty();
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'undo is no-op after deferred commit fired',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule();
        return buildBloc();
      },
      seed: () {
        final slot = generatedSlot();
        return seedTeacherDashboardSuccess(
          upcomingSessions: const [],
          availability: [slot],
        );
      },
      act: (b) async {
        final slot = generatedSlot();
        b.add(AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slot));
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.availability.isEmpty;
        });
        fakeTimers.fireAll();
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.pendingDeletes.isEmpty;
        });
        b.add(AvailabilitySlotDeleteUndone(slotId: slot.slotId));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(state.availability).isEmpty();
        check(scheduleRepo.overrides).length.equals(1);
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'deferred commit withdraws legacy slot when timer fires',
      build: () {
        availabilityProvider.published.addAll([
          makeSlot(slotId: 'slot_1'),
          makeSlot(slotId: 'slot_2'),
        ]);
        return buildBloc();
      },
      seed: () => seedTeacherDashboardSuccess(
        upcomingSessions: const [],
        availability: [
          makeSlot(slotId: 'slot_1'),
          makeSlot(slotId: 'slot_2'),
        ],
      ),
      act: (b) async {
        b.add(
          AvailabilitySlotRemoved(
            teacherId: 'teacher_1',
            slot: makeSlot(slotId: 'slot_1'),
          ),
        );
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.availability.length == 1;
        });
        fakeTimers.fireAll();
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.pendingDeletes.isEmpty;
        });
      },
      expect: () => [
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(state.availability).length.equals(1);
        check(state.availability.first.slotId).equals('slot_2');
        check(availabilityProvider.withdrawn).contains('slot_1');
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'booked at commit time refetches and shows failure',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule();
        return buildBloc();
      },
      seed: () {
        final slot = generatedSlot();
        return seedTeacherDashboardSuccess(
          upcomingSessions: const [],
          availability: [slot],
        );
      },
      act: (b) async {
        final slot = generatedSlot();
        b.add(AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slot));
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.availability.isEmpty;
        });
        sessionRepo.sessions = [
          makeSession(
            teacherId: 'teacher_1',
            studentId: 'student_1',
            startsAt: slot.startsAt,
          ),
        ];
        bookedSlotLockRepo.seedHardLock(
          teacherId: 'teacher_1',
          startUtc: slot.startsAt.toUtc(),
        );
        fakeTimers.fireAll();
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess &&
              s.slotFailure is SlotUnavailableFailure;
        });
      },
      expect: () => [
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(state.slotFailure).isA<SlotUnavailableFailure>();
        check(state.pendingDeletes).isEmpty();
        check(scheduleRepo.overrides).isEmpty();
        check(spyGetAvailability.callCount).equals(1);
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'deferred commit failure restores slot',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule();
        scheduleRepo.failWith = const NetworkFailure();
        return buildBloc();
      },
      seed: () {
        final slot = generatedSlot();
        return seedTeacherDashboardSuccess(
          upcomingSessions: const [],
          availability: [slot],
        );
      },
      act: (b) async {
        b.add(
          AvailabilitySlotRemoved(
            teacherId: 'teacher_1',
            slot: generatedSlot(),
          ),
        );
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.availability.isEmpty;
        });
        fakeTimers.fireAll();
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.availability.isNotEmpty;
        });
      },
      expect: () => [
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(state.availability).length.equals(1);
        check(state.slotFailure).isA<NetworkFailure>();
        check(state.pendingDeletes).isEmpty();
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'multiple deletes keep only latest undoable',
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
        return buildBloc();
      },
      act: (b) async {
        b.add(const TeacherDashboardLoadRequested(teacherId: 'teacher_1'));
        await b.stream.firstWhere((s) => s is TeacherDashboardSuccess);
        final before = b.state as TeacherDashboardSuccess;
        final slots = before.availability.take(2).toList();
        b.add(
          AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slots[0]),
        );
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.pendingDeletes.length == 1;
        });
        b.add(
          AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slots[1]),
        );
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.pendingDeletes.length == 2;
        });
      },
      expect: () => [
        isA<TeacherDashboardLoading>(),
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(state.pendingDeletes).length.equals(2);
        check(state.undoableSlotId).equals(
          state.pendingDeletes.values.last.snapshot.slotId,
        );
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'AvailabilitySlotRemoved on last window day drops slot optimistically',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule();
        return buildBloc();
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
          return s is TeacherDashboardSuccess &&
              !s.availability.any((s) => s.slotId == target.slotId);
        });
        fakeTimers.fireAll();
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.pendingDeletes.isEmpty;
        });
        final after = b.state as TeacherDashboardSuccess;
        check(after.availability.length).equals(countBefore - 1);
      },
      expect: () => [
        isA<TeacherDashboardLoading>(),
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (b) {
        check(scheduleRepo.overrides).isNotEmpty();
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
        return buildBloc();
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
          return s is TeacherDashboardSuccess &&
              !s.availability.any((s) => s.slotId == saturdaySlot.slotId);
        });
        fakeTimers.fireAll();
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.pendingDeletes.isEmpty;
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
        return buildBloc();
      },
      seed: () => seedTeacherDashboardSuccess(
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
        check(state.pendingDeletes).isEmpty();
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'AvailabilitySlotRemoved ignores duplicate delete for same slot',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule();
        return buildBloc();
      },
      seed: () {
        final slot = generatedSlot();
        return seedTeacherDashboardSuccess(
          upcomingSessions: const [],
          availability: [slot],
        );
      },
      act: (b) async {
        final slot = generatedSlot();
        b.add(AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slot));
        await b.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.pendingDeletes.isNotEmpty;
        });
        b.add(AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slot));
      },
      expect: () => [isA<TeacherDashboardSuccess>()],
      verify: (_) {
        check(fakeTimers.factoryCallCount).equals(1);
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'AvailabilitySlotRemoved blocks booked generated slot at tap',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule();
        return buildBloc();
      },
      seed: () {
        final slot = generatedSlot();
        return seedTeacherDashboardSuccess(
          upcomingSessions: const [],
          availability: [
            TeacherAvailability(
              slotId: slot.slotId,
              teacherId: slot.teacherId,
              startsAt: slot.startsAt,
              endsAt: slot.endsAt,
              isBooked: true,
            ),
          ],
        );
      },
      act: (b) {
        final slot = generatedSlot();
        b.add(
          AvailabilitySlotRemoved(
            teacherId: 'teacher_1',
            slot: TeacherAvailability(
              slotId: slot.slotId,
              teacherId: slot.teacherId,
              startsAt: slot.startsAt,
              endsAt: slot.endsAt,
              isBooked: true,
            ),
          ),
        );
      },
      expect: () => [isA<TeacherDashboardSuccess>()],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(state.availability).length.equals(1);
        check(state.slotFailure).isA<SlotUnavailableFailure>();
        check(scheduleRepo.getOverrideByDateCallCount).equals(0);
        check(state.pendingDeletes).isEmpty();
      },
    );

    group('slot deletion regression', () {
      // Manual QA (device / RTL):
      // - Delete 3+ slots quickly without Undo; count reaches 0, no ghost rows.
      // - Delete A then B; Undo only B's toast; A stays deleted, count correct.
      // - Delete then pull-to-refresh before/after undo toast; committed deletes
      //   persist, undone slot remains; verify count 1→0 and Undo 0→1.
      // - Arabic RTL: undo toast + slot list layout and count label readable.
      // - Delete A, delete B before A's toast clears; Undo restores B only.

      blocTest<TeacherDashboardBloc, TeacherDashboardState>(
        'rapid multi-delete without undo removes all slots and commits',
        build: () {
          scheduleRepo.schedule = makeWeeklySchedule();
          return buildBloc();
        },
        seed: () => seedTeacherDashboardSuccess(
          upcomingSessions: const [],
          availability: threeDistinctGeneratedSlots(),
        ),
        act: (b) async {
          final slots = threeDistinctGeneratedSlots();
          for (final slot in slots) {
            b.add(AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slot));
          }
          await b.stream.firstWhere((s) {
            return s is TeacherDashboardSuccess && s.pendingDeletes.length == 3;
          });
          fakeTimers.fireAll();
          await b.stream.firstWhere((s) {
            return s is TeacherDashboardSuccess && s.pendingDeletes.isEmpty;
          });
        },
        expect: () => List<Matcher>.filled(6, isA<TeacherDashboardSuccess>()),
        verify: (b) {
          final state = b.state as TeacherDashboardSuccess;
          check(state.availability).isEmpty();
          check(state.pendingDeletes).isEmpty();
          check(state.undoableSlotId).isNull();
          check(state.slotFailure).isNull();
          check(scheduleRepo.overrides).isNotEmpty();
          check(fakeTimers.factoryCallCount).equals(3);
          final slotIds = state.availability.map((s) => s.slotId).toSet();
          check(slotIds.length).equals(state.availability.length);
        },
      );

      blocTest<TeacherDashboardBloc, TeacherDashboardState>(
        'rapid multi-delete with partial undo restores only undone slot',
        build: () {
          scheduleRepo.schedule = makeWeeklySchedule();
          return buildBloc();
        },
        seed: () => seedTeacherDashboardSuccess(
          upcomingSessions: const [],
          availability: threeDistinctGeneratedSlots(),
        ),
        act: (b) async {
          final slots = threeDistinctGeneratedSlots();
          for (final slot in slots) {
            b.add(AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slot));
          }
          await b.stream.firstWhere((s) {
            return s is TeacherDashboardSuccess && s.pendingDeletes.length == 3;
          });
          final middle = slots[1];
          b.add(AvailabilitySlotDeleteUndone(slotId: middle.slotId));
          await b.stream.firstWhere((s) {
            return s is TeacherDashboardSuccess &&
                s.availability.any((s) => s.slotId == middle.slotId);
          });
          fakeTimers.fireAll();
          await b.stream.firstWhere((s) {
            return s is TeacherDashboardSuccess && s.pendingDeletes.isEmpty;
          });
        },
        expect: () => List<Matcher>.filled(6, isA<TeacherDashboardSuccess>()),
        verify: (b) {
          final state = b.state as TeacherDashboardSuccess;
          final slots = threeDistinctGeneratedSlots();
          check(state.availability).length.equals(1);
          check(state.availability.single.slotId).equals(slots[1].slotId);
          check(state.pendingDeletes).isEmpty();
          check(scheduleRepo.overrides).isNotEmpty();
        },
      );

      test('reload after commits keeps deleted slots gone in source', () async {
        scheduleRepo.schedule = makeWeeklySchedule();
        final testBloc = buildBloc();
        final slots = threeDistinctGeneratedSlots();
        testBloc.emit(
          seedTeacherDashboardSuccess(
            upcomingSessions: const [],
            availability: slots,
          ),
        );

        testBloc.add(
          AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slots[0]),
        );
        testBloc.add(
          AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slots[1]),
        );
        await testBloc.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.pendingDeletes.length == 2;
        });
        fakeTimers.fireAll();
        await testBloc.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.pendingDeletes.isEmpty;
        });

        testBloc.add(
          const TeacherDashboardLoadRequested(teacherId: 'teacher_1'),
        );
        await testBloc.stream.firstWhere((s) => s is TeacherDashboardSuccess);

        final state = testBloc.state as TeacherDashboardSuccess;
        check(state.pendingDeletes).isEmpty();
        check(state.undoableSlotId).isNull();
        check(scheduleRepo.overrides).isNotEmpty();

        final windowFrom = DateTime.utc(2026, 1, 10);
        final windowTo = DateTime.utc(2026, 1, 17);
        final availResult = await spyGetAvailability(
          'teacher_1',
          from: windowFrom,
          to: windowTo,
        );
        availResult.fold(
          (_) => fail('expected Right'),
          (refetched) {
            final ids = refetched.map((s) => s.slotId).toSet();
            check(ids.contains(slots[0].slotId)).isFalse();
            check(ids.contains(slots[1].slotId)).isFalse();
            check(ids.contains(slots[2].slotId)).isTrue();
          },
        );

        await testBloc.close();
      });

      test('reload after undo keeps restored slot from source', () async {
        scheduleRepo.schedule = makeWeeklySchedule();
        final testBloc = buildBloc();
        final slots = threeDistinctGeneratedSlots();
        testBloc.emit(
          seedTeacherDashboardSuccess(
            upcomingSessions: const [],
            availability: slots,
          ),
        );

        testBloc.add(
          AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slots[0]),
        );
        await testBloc.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess && s.pendingDeletes.isNotEmpty;
        });
        testBloc.add(AvailabilitySlotDeleteUndone(slotId: slots[0].slotId));
        await testBloc.stream.firstWhere((s) {
          return s is TeacherDashboardSuccess &&
              s.availability.length == slots.length;
        });

        testBloc.add(
          const TeacherDashboardLoadRequested(teacherId: 'teacher_1'),
        );
        await testBloc.stream.firstWhere((s) => s is TeacherDashboardSuccess);

        check(scheduleRepo.overrides).isEmpty();
        final state = testBloc.state as TeacherDashboardSuccess;
        check(state.pendingDeletes).isEmpty();

        final windowFrom = DateTime.utc(2026, 1, 10);
        final windowTo = DateTime.utc(2026, 1, 17);
        final availResult = await spyGetAvailability(
          'teacher_1',
          from: windowFrom,
          to: windowTo,
        );
        availResult.fold(
          (_) => fail('expected Right'),
          (refetched) {
            final ids = refetched.map((s) => s.slotId).toSet();
            for (final slot in slots) {
              check(ids.contains(slot.slotId)).isTrue();
            }
          },
        );

        await testBloc.close();
      });

      blocTest<TeacherDashboardBloc, TeacherDashboardState>(
        'second delete while first undo pending tracks latest undoable slot',
        build: () {
          scheduleRepo.schedule = makeWeeklySchedule();
          return buildBloc();
        },
        seed: () {
          final slots = threeDistinctGeneratedSlots();
          return seedTeacherDashboardSuccess(
            upcomingSessions: const [],
            availability: slots.take(2).toList(),
          );
        },
        act: (b) async {
          final slots = threeDistinctGeneratedSlots().take(2).toList();
          b.add(
            AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slots[0]),
          );
          await b.stream.firstWhere((s) {
            return s is TeacherDashboardSuccess && s.pendingDeletes.length == 1;
          });
          b.add(
            AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slots[1]),
          );
          await b.stream.firstWhere((s) {
            return s is TeacherDashboardSuccess && s.pendingDeletes.length == 2;
          });
        },
        expect: () => [
          isA<TeacherDashboardSuccess>(),
          isA<TeacherDashboardSuccess>(),
        ],
        verify: (b) {
          final state = b.state as TeacherDashboardSuccess;
          final slots = threeDistinctGeneratedSlots().take(2).toList();
          check(state.availability).isEmpty();
          check(state.undoableSlotId).equals(slots[1].slotId);
          check(state.pendingDeletes.length).equals(2);
          check(state.pendingDeletes).containsKey(slots[0].slotId);
          check(state.pendingDeletes).containsKey(slots[1].slotId);
          check(fakeTimers.factoryCallCount).equals(2);
        },
      );

      blocTest<TeacherDashboardBloc, TeacherDashboardState>(
        'undo on latest pending delete does not restore earlier deleted slot',
        build: () {
          scheduleRepo.schedule = makeWeeklySchedule();
          return buildBloc();
        },
        seed: () {
          final slots = threeDistinctGeneratedSlots().take(2).toList();
          return seedTeacherDashboardSuccess(
            upcomingSessions: const [],
            availability: slots,
          );
        },
        act: (b) async {
          final slots = threeDistinctGeneratedSlots().take(2).toList();
          b.add(
            AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slots[0]),
          );
          b.add(
            AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slots[1]),
          );
          await b.stream.firstWhere((s) {
            return s is TeacherDashboardSuccess && s.pendingDeletes.length == 2;
          });
          b.add(AvailabilitySlotDeleteUndone(slotId: slots[1].slotId));
          await b.stream.firstWhere((s) {
            return s is TeacherDashboardSuccess &&
                s.availability.length == 1 &&
                s.availability.single.slotId == slots[1].slotId;
          });
        },
        expect: () => [
          isA<TeacherDashboardSuccess>(),
          isA<TeacherDashboardSuccess>(),
          isA<TeacherDashboardSuccess>(),
        ],
        verify: (b) {
          final state = b.state as TeacherDashboardSuccess;
          final slots = threeDistinctGeneratedSlots().take(2).toList();
          check(state.availability.single.slotId).equals(slots[1].slotId);
          check(state.pendingDeletes).length.equals(1);
          check(state.pendingDeletes).containsKey(slots[0].slotId);
          check(state.undoableSlotId).isNull();
        },
      );
    });

    group('delete slot concurrency', () {
      blocTest<TeacherDashboardBloc, TeacherDashboardState>(
        'sequential transformer processes burst deletes without dropping',
        build: () {
          scheduleRepo.schedule = makeWeeklySchedule();
          return buildBloc();
        },
        seed: () => seedTeacherDashboardSuccess(
          upcomingSessions: const [],
          availability: threeDistinctGeneratedSlots(),
        ),
        act: (b) {
          final slots = threeDistinctGeneratedSlots();
          for (final slot in slots) {
            b.add(AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slot));
          }
        },
        expect: () => List<Matcher>.filled(3, isA<TeacherDashboardSuccess>()),
        verify: (b) {
          final state = b.state as TeacherDashboardSuccess;
          check(state.availability).isEmpty();
          check(state.pendingDeletes).length.equals(3);
          check(fakeTimers.factoryCallCount).equals(3);
        },
      );

      blocTest<TeacherDashboardBloc, TeacherDashboardState>(
        'reload during pending deletes clears optimistic pending state',
        build: () {
          scheduleRepo.schedule = makeWeeklySchedule();
          return buildBloc();
        },
        seed: () {
          final slots = threeDistinctGeneratedSlots();
          return seedTeacherDashboardSuccess(
            upcomingSessions: const [],
            availability: slots,
            pendingDeletes: {
              slots[0].slotId: PendingSlotDelete(
                snapshot: slots[0],
                isGenerated: true,
                teacherId: 'teacher_1',
                cancelTimer: testCommitTimerFactory(
                  const Duration(days: 365),
                  () {},
                ),
              ),
            },
            undoableSlotId: slots[0].slotId,
          );
        },
        act: (b) async {
          b.add(const TeacherDashboardLoadRequested(teacherId: 'teacher_1'));
          await b.stream.firstWhere((s) => s is TeacherDashboardSuccess);
        },
        expect: () => [
          isA<TeacherDashboardSuccess>().having(
            (s) => s.isRefreshing,
            'isRefreshing',
            isTrue,
          ),
          isA<TeacherDashboardSuccess>().having(
            (s) => s.isRefreshing,
            'isRefreshing',
            isFalse,
          ),
        ],
        verify: (b) {
          final state = b.state as TeacherDashboardSuccess;
          check(state.pendingDeletes).isEmpty();
          check(state.undoableSlotId).isNull();
          check(state.availability).isNotEmpty();
          check(state.refreshDiscardedPendingCount).equals(1);
        },
      );

      blocTest<TeacherDashboardBloc, TeacherDashboardState>(
        'refresh during pending deletes cancels timers and skips orphan commits',
        build: () {
          scheduleRepo.schedule = makeWeeklySchedule();
          return buildBloc();
        },
        seed: () {
          final slots = threeDistinctGeneratedSlots();
          return seedTeacherDashboardSuccess(
            upcomingSessions: const [],
            availability: [slots[2]],
          );
        },
        act: (b) async {
          final slots = threeDistinctGeneratedSlots();
          b.add(
            AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slots[0]),
          );
          b.add(
            AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slots[1]),
          );
          await b.stream.firstWhere((s) {
            return s is TeacherDashboardSuccess && s.pendingDeletes.length == 2;
          });
          check(fakeTimers.scheduled).length.equals(2);

          b.add(const TeacherDashboardLoadRequested(teacherId: 'teacher_1'));
          await b.stream.firstWhere((s) => s is TeacherDashboardSuccess);

          check(fakeTimers.cancelCallCount).equals(2);
          check(fakeTimers.scheduled).isEmpty();
          check(scheduleRepo.overrides).isEmpty();

          fakeTimers.fireAll();
          await Future<void>.delayed(Duration.zero);

          check(scheduleRepo.overrides).isEmpty();
        },
        expect: () => [
          isA<TeacherDashboardSuccess>(),
          isA<TeacherDashboardSuccess>(),
          isA<TeacherDashboardSuccess>().having(
            (s) => s.isRefreshing,
            'isRefreshing',
            isTrue,
          ),
          isA<TeacherDashboardSuccess>().having(
            (s) => s.isRefreshing,
            'isRefreshing',
            isFalse,
          ),
        ],
        verify: (b) {
          final state = b.state as TeacherDashboardSuccess;
          check(state.pendingDeletes).isEmpty();
          check(state.undoableSlotId).isNull();
          check(scheduleRepo.overrides).isEmpty();
        },
      );

      blocTest<TeacherDashboardBloc, TeacherDashboardState>(
        'commit after slot removed from pendingDeletes is skipped',
        build: () {
          scheduleRepo.schedule = makeWeeklySchedule();
          return buildBloc();
        },
        seed: () => seedTeacherDashboardSuccess(
          upcomingSessions: [],
          availability: [],
          pendingDeletes: {},
        ),
        act: (b) async {
          b.add(CommitPendingSlotDelete(slotId: generatedSlot().slotId));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => <Matcher>[],
        verify: (_) {
          check(scheduleRepo.overrides).isEmpty();
          check(availabilityProvider.withdrawn).isEmpty();
        },
      );

      blocTest<TeacherDashboardBloc, TeacherDashboardState>(
        'commit of older pending delete keeps latest undoable slot',
        build: () {
          scheduleRepo.schedule = makeWeeklySchedule();
          return buildBloc();
        },
        seed: () {
          final slots = threeDistinctGeneratedSlots().take(2).toList();
          return seedTeacherDashboardSuccess(
            upcomingSessions: const [],
            availability: slots,
          );
        },
        act: (b) async {
          final slots = threeDistinctGeneratedSlots().take(2).toList();
          b.add(
            AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slots[0]),
          );
          b.add(
            AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slots[1]),
          );
          await b.stream.firstWhere((s) {
            return s is TeacherDashboardSuccess && s.pendingDeletes.length == 2;
          });
          b.add(CommitPendingSlotDelete(slotId: slots[0].slotId));
          await b.stream.firstWhere((s) {
            return s is TeacherDashboardSuccess &&
                !s.pendingDeletes.containsKey(slots[0].slotId);
          });
        },
        expect: () => [
          isA<TeacherDashboardSuccess>(),
          isA<TeacherDashboardSuccess>(),
          isA<TeacherDashboardSuccess>(),
        ],
        verify: (b) {
          final state = b.state as TeacherDashboardSuccess;
          final slots = threeDistinctGeneratedSlots().take(2).toList();
          check(state.pendingDeletes).containsKey(slots[1].slotId);
          check(state.undoableSlotId).equals(slots[1].slotId);
          check(scheduleRepo.overrides).length.equals(1);
        },
      );

      blocTest<TeacherDashboardBloc, TeacherDashboardState>(
        'undo and delete events process sequentially in arrival order',
        build: () {
          scheduleRepo.schedule = makeWeeklySchedule();
          return buildBloc();
        },
        seed: () {
          final slots = threeDistinctGeneratedSlots().take(2).toList();
          return seedTeacherDashboardSuccess(
            upcomingSessions: const [],
            availability: slots,
          );
        },
        act: (b) async {
          final slots = threeDistinctGeneratedSlots().take(2).toList();
          b.add(
            AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slots[0]),
          );
          await b.stream.firstWhere((s) {
            return s is TeacherDashboardSuccess && s.pendingDeletes.length == 1;
          });
          b.add(
            AvailabilitySlotRemoved(teacherId: 'teacher_1', slot: slots[1]),
          );
          await b.stream.firstWhere((s) {
            return s is TeacherDashboardSuccess && s.pendingDeletes.length == 2;
          });
          b.add(AvailabilitySlotDeleteUndone(slotId: slots[1].slotId));
          await b.stream.firstWhere((s) {
            return s is TeacherDashboardSuccess &&
                s.availability.any((s) => s.slotId == slots[1].slotId);
          });
        },
        expect: () => [
          isA<TeacherDashboardSuccess>(),
          isA<TeacherDashboardSuccess>(),
          isA<TeacherDashboardSuccess>(),
        ],
        verify: (b) {
          final state = b.state as TeacherDashboardSuccess;
          final slots = threeDistinctGeneratedSlots().take(2).toList();
          check(state.availability.single.slotId).equals(slots[1].slotId);
          check(state.pendingDeletes).containsKey(slots[0].slotId);
        },
      );
    });

    test('close fires deferred commits without emitting', () async {
      scheduleRepo.schedule = makeWeeklySchedule();
      final slot = generatedSlot();
      final testBloc = buildBloc();
      testBloc.emit(
        seedTeacherDashboardSuccess(
          upcomingSessions: const [],
          availability: const [],
          pendingDeletes: {
            slot.slotId: PendingSlotDelete(
              snapshot: slot,
              isGenerated: true,
              teacherId: 'teacher_1',
              cancelTimer: testCommitTimerFactory(
                const Duration(seconds: 5),
                () {},
              ),
            ),
          },
        ),
      );

      final statesBeforeClose = <TeacherDashboardState>[];
      final sub = testBloc.stream.listen(statesBeforeClose.add);

      await testBloc.close();
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      check(statesBeforeClose).isEmpty();
      check(scheduleRepo.overrides).length.equals(1);
    });
  });
}
