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
  late TeacherDashboardBloc bloc;

  final fixedNow = DateTime.utc(2026, 1, 9);

  setUpAll(tz_data.initializeTimeZones);

  setUp(() {
    sessionRepo = FakeSessionRepository();
    scheduleRepo = FakeScheduleRepository();
    availabilityProvider = FakeAvailabilityProvider();
    blockGeneratedSlot = BlockGeneratedSlotUseCase(scheduleRepo);
    bloc = TeacherDashboardBloc(
      getTeacherSessions: GetTeacherSessionsUseCase(sessionRepo),
      getAvailability: buildGetTeacherAvailabilityUseCase(
        scheduleRepository: scheduleRepo,
        sessionRepository: sessionRepo,
        now: () => fixedNow,
      ),
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
      'AvailabilitySlotRemoved blocks generated slot and refreshes list',
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
        check(scheduleRepo.overrides).length.equals(1);
        check(state.isUpdatingAvailability).isFalse();
        check(state.slotFailure).isNull();
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'AvailabilitySlotRemoved removes legacy slot via provider',
      build: () => bloc,
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
  });
}
