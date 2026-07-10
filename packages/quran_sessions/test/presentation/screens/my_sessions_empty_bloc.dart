import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_auth_session.dart';
import '../../helpers/fakes/fake_booking_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/lifecycle_test_helpers.dart';

/// Seeds [MySessionsBloc] with [MySessionsEmpty] and ignores events.
class MySessionsEmptyBloc extends MySessionsBloc {
  MySessionsEmptyBloc()
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
    emit(const MySessionsEmpty());
  }

  @override
  void add(MySessionsEvent event) {}
}
