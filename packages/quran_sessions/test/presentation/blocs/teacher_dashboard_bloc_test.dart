import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/src/domain/failures/quran_sessions_failure.dart';
import '../../../lib/src/domain/usecases/get_teacher_availability_usecase.dart';
import '../../../lib/src/domain/usecases/get_teacher_sessions_usecase.dart';
import '../../../lib/src/presentation/blocs/teacher_dashboard/teacher_dashboard_bloc.dart';
import '../../../lib/src/presentation/blocs/teacher_dashboard/teacher_dashboard_event.dart';
import '../../../lib/src/presentation/blocs/teacher_dashboard/teacher_dashboard_state.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fixtures.dart';

void main() {
  late FakeSessionRepository sessionRepo;
  late FakeTeacherRepository teacherRepo;
  late FakeAvailabilityProvider availabilityProvider;
  late TeacherDashboardBloc bloc;

  setUp(() {
    sessionRepo = FakeSessionRepository();
    teacherRepo = FakeTeacherRepository();
    availabilityProvider = FakeAvailabilityProvider();
    bloc = TeacherDashboardBloc(
      getTeacherSessions: GetTeacherSessionsUseCase(sessionRepo),
      getAvailability: GetTeacherAvailabilityUseCase(teacherRepo),
      availabilityProvider: availabilityProvider,
    );
  });

  tearDown(() => bloc.close());

  group('TeacherDashboardBloc', () {
    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'emits [Loading, Empty] when no sessions or slots',
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
      'emits [Loading, Success] when sessions and slots are present',
      build: () {
        sessionRepo.sessions = [
          makeSession(
            teacherId: 'teacher_1',
            studentId: 'student_1',
            startsAt: DateTime.now().add(const Duration(hours: 2)),
          ),
        ];
        teacherRepo.availability = [
          makeSlot(teacherId: 'teacher_1'),
        ];
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
        check(state.availability).length.equals(1);
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
        isA<TeacherDashboardSuccess>(), // isUpdatingAvailability = true
        isA<TeacherDashboardSuccess>(), // slot appended
      ],
      verify: (b) {
        final state = b.state as TeacherDashboardSuccess;
        check(state.availability).length.equals(1);
        check(state.isUpdatingAvailability).isFalse();
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'AvailabilitySlotRemoved removes matching slot',
      build: () => bloc,
      seed: () => TeacherDashboardSuccess(
        upcomingSessions: const [],
        availability: [
          makeSlot(slotId: 'slot_1'),
          makeSlot(slotId: 'slot_2'),
        ],
      ),
      act: (b) => b.add(const AvailabilitySlotRemoved(slotId: 'slot_1')),
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
