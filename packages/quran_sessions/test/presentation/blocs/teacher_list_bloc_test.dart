import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_sessions/src/domain/entities/teacher_availability.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/usecases/get_teacher_availability_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/get_teachers_usecase.dart';
import 'package:quran_sessions/src/presentation/models/teacher_availability_summary.dart';
import 'package:quran_sessions/src/presentation/blocs/teacher_list/teacher_list_bloc.dart';
import 'package:quran_sessions/src/presentation/blocs/teacher_list/teacher_list_event.dart';
import 'package:quran_sessions/src/presentation/blocs/teacher_list/teacher_list_state.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fixtures.dart';

class _StaticAvailabilityUseCase extends GetTeacherAvailabilityUseCase {
  _StaticAvailabilityUseCase(this.slots)
    : super(
        scheduleRepository: FakeScheduleRepository(),
        bookedSlotLocks: FakeBookedSlotLockRepository(),
      );

  final Map<String, List<TeacherAvailability>> slots;

  @override
  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>> call(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  }) async {
    return Right(slots[teacherId] ?? const []);
  }
}

void main() {
  late FakeTeacherRepository repo;
  late TeacherListBloc bloc;

  setUp(() {
    repo = FakeTeacherRepository();
    bloc = TeacherListBloc(
      GetTeachersUseCase(repo),
      _StaticAvailabilityUseCase(const {}),
    );
  });

  tearDown(() => bloc.close());

  group('TeacherListBloc', () {
    blocTest<TeacherListBloc, TeacherListState>(
      'emits [Loading, Success] when teachers are returned',
      build: () {
        repo.teachers = [makeTeacher(id: '1'), makeTeacher(id: '2')];
        return bloc;
      },
      act: (b) => b.add(const LoadTeachersRequested()),
      expect: () => [
        isA<TeacherListLoading>(),
        isA<TeacherListSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherListSuccess;
        check(state.teachers).length.equals(2);
        check(state.hasMore).isFalse();
      },
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'emits availability summaries from generated availability use case',
      build: () {
        final anchor = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          12,
        );
        repo.teachers = [makeTeacher(id: 'teacher_with_slots')];
        return TeacherListBloc(
          GetTeachersUseCase(repo),
          _StaticAvailabilityUseCase({
            'teacher_with_slots': [
              makeSlot(
                teacherId: 'teacher_with_slots',
                startsAt: anchor.add(const Duration(hours: 2)),
              ),
            ],
          }),
        );
      },
      act: (b) => b.add(const LoadTeachersRequested()),
      expect: () => [
        isA<TeacherListLoading>(),
        isA<TeacherListSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherListSuccess;
        final summary = state.availabilitySummaries['teacher_with_slots'];
        check(summary).isNotNull();
        check(summary!.status).equals(TeacherAvailabilityStatus.availableToday);
        check(summary.hasAvailableSlots).isTrue();
      },
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'emits [Loading, Empty] when no teachers match filter',
      build: () {
        repo.teachers = [
          makeTeacher(specializations: ['tajweed']),
        ];
        return bloc;
      },
      act: (b) => b.add(const LoadTeachersRequested(specialization: 'hifz')),
      expect: () => [
        isA<TeacherListLoading>(),
        isA<TeacherListEmpty>(),
      ],
      verify: (b) {
        final state = b.state as TeacherListEmpty;
        check(state.activeSpecialization).equals('hifz');
      },
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'emits [Loading, Failure] on repository error',
      build: () {
        repo.failWith = const NetworkFailure();
        return bloc;
      },
      act: (b) => b.add(const LoadTeachersRequested()),
      expect: () => [
        isA<TeacherListLoading>(),
        isA<TeacherListFailure>(),
      ],
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'LoadMoreTeachersRequested is dropped when state is not Success',
      build: () => bloc,
      act: (b) => b.add(const LoadMoreTeachersRequested()),
      expect: () => <TeacherListState>[],
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'TeacherFilterChanged re-fetches from page 1 with new filter',
      build: () {
        repo.teachers = [
          makeTeacher(specializations: ['hifz']),
        ];
        return bloc;
      },
      act: (b) => b.add(const TeacherFilterChanged(specialization: 'hifz')),
      expect: () => [
        isA<TeacherListLoading>(),
        isA<TeacherListSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherListSuccess;
        check(state.activeSpecialization).equals('hifz');
      },
    );
  });
}
