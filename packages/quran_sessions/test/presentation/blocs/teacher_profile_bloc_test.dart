import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/src/domain/failures/quran_sessions_failure.dart';
import '../../../lib/src/domain/usecases/get_teacher_availability_usecase.dart';
import '../../../lib/src/domain/usecases/get_teacher_profile_usecase.dart';
import '../../../lib/src/presentation/blocs/teacher_profile/teacher_profile_bloc.dart';
import '../../../lib/src/presentation/blocs/teacher_profile/teacher_profile_event.dart';
import '../../../lib/src/presentation/blocs/teacher_profile/teacher_profile_state.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fixtures.dart';

void main() {
  late FakeTeacherRepository repo;
  late TeacherProfileBloc bloc;

  final now = DateTime.now();

  setUp(() {
    repo = FakeTeacherRepository();
    bloc = TeacherProfileBloc(
      getProfile: GetTeacherProfileUseCase(repo),
      getAvailability: GetTeacherAvailabilityUseCase(repo),
    );
  });

  tearDown(() => bloc.close());

  group('TeacherProfileBloc', () {
    blocTest<TeacherProfileBloc, TeacherProfileState>(
      'emits [Loading, Success] when profile and slots load',
      build: () {
        repo.teachers = [makeTeacher()];
        repo.availability = [
          makeSlot(startsAt: now.add(const Duration(days: 1))),
        ];
        return bloc;
      },
      act: (b) => b.add(
        TeacherProfileRequested(
          teacherId: 'teacher_1',
          availabilityFrom: now,
          availabilityTo: now.add(const Duration(days: 7)),
        ),
      ),
      expect: () => [
        isA<TeacherProfileLoading>(),
        isA<TeacherProfileSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherProfileSuccess;
        check(state.teacher.id).equals('teacher_1');
        check(state.availability).length.equals(1);
      },
    );

    blocTest<TeacherProfileBloc, TeacherProfileState>(
      'emits [Loading, Failure] when profile not found',
      build: () {
        repo.failWith = const NotFoundFailure('QuranTeacher');
        return bloc;
      },
      act: (b) => b.add(
        TeacherProfileRequested(
          teacherId: 'missing',
          availabilityFrom: now,
          availabilityTo: now.add(const Duration(days: 7)),
        ),
      ),
      expect: () => [
        isA<TeacherProfileLoading>(),
        isA<TeacherProfileFailure>(),
      ],
    );

    blocTest<TeacherProfileBloc, TeacherProfileState>(
      'AvailabilityWeekChanged refreshes slots without full reload',
      build: () {
        repo.teachers = [makeTeacher()];
        return bloc;
      },
      seed: () => TeacherProfileSuccess(
        teacher: makeTeacher(),
        availability: [makeSlot()],
        reviews: const [],
      ),
      act: (b) => b.add(
        AvailabilityWeekChanged(
          teacherId: 'teacher_1',
          from: now.add(const Duration(days: 7)),
          to: now.add(const Duration(days: 14)),
        ),
      ),
      expect: () => [
        isA<TeacherProfileSuccess>(), // isLoadingAvailability = true
        isA<TeacherProfileSuccess>(), // refreshed slots
      ],
      verify: (b) {
        final state = b.state as TeacherProfileSuccess;
        check(state.isLoadingAvailability).isFalse();
      },
    );
  });
}
