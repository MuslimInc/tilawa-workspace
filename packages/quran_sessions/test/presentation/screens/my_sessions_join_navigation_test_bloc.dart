import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_auth_session.dart';
import '../../helpers/fakes/fake_booking_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/lifecycle_test_helpers.dart';

/// Seeds [MySessionsBloc] and resolves join requests immediately so join
/// navigation can be asserted without a real call provider round-trip.
class MySessionsJoinNavigationTestBloc extends MySessionsBloc {
  MySessionsJoinNavigationTestBloc({required MySessionsSuccess seed})
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
  void add(MySessionsEvent event) {
    if (event is MySessionsLoadRequested) {
      return;
    }
    if (event is SessionJoinRequested) {
      final current = state;
      if (current is! MySessionsSuccess) {
        return;
      }
      emit(
        current.copyWith(
          clearJoinInProgress: true,
          joinCompletedSessionId: event.sessionId,
        ),
      );
      return;
    }
    super.add(event);
  }
}
