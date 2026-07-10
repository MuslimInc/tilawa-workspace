import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';

/// Seeds [TeacherProfileBloc] with a fixed state and ignores incoming events.
class TeacherProfileTestBloc extends TeacherProfileBloc {
  TeacherProfileTestBloc(TeacherProfileSuccess seed)
    : super(
        getProfile: GetTeacherProfileUseCase(FakeTeacherRepository()),
        getAvailability: buildGetTeacherAvailabilityUseCase(
          scheduleRepository: FakeScheduleRepository(),
          sessionRepository: FakeSessionRepository(),
        ),
      ) {
    emit(seed);
  }

  @override
  void add(TeacherProfileEvent event) {}
}
