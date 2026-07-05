import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_auth_session.dart';
import '../../helpers/fakes/fake_booking_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/lifecycle_test_helpers.dart';

/// Seeds [MySessionsBloc] with a fixed success state and ignores events.
class MySessionsLayoutBloc extends MySessionsBloc {
  MySessionsLayoutBloc({required MySessionsSuccess seed})
    : super(
        getStudentSessions: GetStudentSessionsUseCase(FakeSessionRepository()),
        cancelSession: buildCancelSessionViaServerUseCase(),
        submitReview: SubmitReviewUseCase(FakeBookingRepository()),
        joinSession: JoinSessionUseCase(
          sessionRepository: FakeSessionRepository(),
          callProvider: const MockSessionCallProvider(),
          authSession: const FakeAuthSession('student_1'),
          teacherProfileRepository: FakeTeacherProfileRepository(),
        ),
        studentId: 'student_1',
      ) {
    emit(seed);
  }

  @override
  void add(MySessionsEvent event) {}
}
