import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/usecases/get_teacher_profile_usecase.dart';
import 'package:quran_sessions/src/presentation/blocs/teacher_profile/teacher_profile_bloc.dart';
import 'package:quran_sessions/src/presentation/blocs/teacher_profile/teacher_profile_event.dart';
import 'package:quran_sessions/src/presentation/blocs/teacher_profile/teacher_profile_state.dart';
import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fixtures.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  late FakeTeacherRepository repo;
  late FakeScheduleRepository scheduleRepo;
  late FakeSessionRepository sessionRepo;
  late TeacherProfileBloc bloc;

  final fixedNow = DateTime.utc(2026, 1, 9);
  final now = fixedNow;

  setUpAll(tz_data.initializeTimeZones);

  setUp(() {
    repo = FakeTeacherRepository();
    scheduleRepo = FakeScheduleRepository();
    sessionRepo = FakeSessionRepository();
    bloc = TeacherProfileBloc(
      getProfile: GetTeacherProfileUseCase(repo),
      getAvailability: buildGetTeacherAvailabilityUseCase(
        scheduleRepository: scheduleRepo,
        sessionRepository: sessionRepo,
        now: () => fixedNow,
      ),
    );
  });

  tearDown(() => bloc.close());

  group('TeacherProfileBloc', () {
    blocTest<TeacherProfileBloc, TeacherProfileState>(
      'emits [Loading, Success] when profile and generated slots load',
      build: () {
        repo.teachers = [makeTeacher()];
        scheduleRepo.schedule = makeWeeklySchedule();
        return bloc;
      },
      act: (b) => b.add(
        TeacherProfileRequested(
          teacherId: 'teacher_1',
          availabilityFrom: DateTime.utc(2026, 1, 10),
          availabilityTo: DateTime.utc(2026, 1, 17),
        ),
      ),
      expect: () => [
        isA<TeacherProfileLoading>(),
        isA<TeacherProfileSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherProfileSuccess;
        check(state.teacher.id).equals('teacher_1');
        check(state.availability).isNotEmpty();
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
      'AvailabilityWeekChanged refreshes generated slots without full reload',
      build: () {
        repo.teachers = [makeTeacher()];
        scheduleRepo.schedule = makeWeeklySchedule();
        return bloc;
      },
      seed: () => TeacherProfileSuccess(
        teacher: makeTeacher(),
        availability: const [],
        reviews: const [],
      ),
      act: (b) => b.add(
        AvailabilityWeekChanged(
          teacherId: 'teacher_1',
          from: DateTime.utc(2026, 1, 17),
          to: DateTime.utc(2026, 1, 24),
        ),
      ),
      expect: () => [
        isA<TeacherProfileSuccess>(),
        isA<TeacherProfileSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherProfileSuccess;
        check(state.isLoadingAvailability).isFalse();
      },
    );
  });
}
