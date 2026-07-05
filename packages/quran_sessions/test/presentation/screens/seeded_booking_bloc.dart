import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_market_config_repository.dart';
import '../../helpers/fakes/fake_session_policy_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fakes/fake_user_profile_repository.dart';
import '../../helpers/lifecycle_test_helpers.dart';

/// Seeds [BookingBloc] with a fixed state and ignores incoming events.
class SeededBookingBloc extends BookingBloc {
  SeededBookingBloc({required BookingSelecting seed})
    : super(
        getAvailability: buildGetTeacherAvailabilityUseCase(
          scheduleRepository: FakeScheduleRepository(),
          sessionRepository: FakeSessionRepository(),
        ),
        submitBooking: buildSubmitSessionBookingUseCase(
          getAvailability: buildGetTeacherAvailabilityUseCase(
            scheduleRepository: FakeScheduleRepository(),
            sessionRepository: FakeSessionRepository(),
          ),
        ),
        validateEligibility: ValidateBookingEligibilityUseCase(
          profileRepository: FakeUserProfileRepository(),
          policyRepository: FakeSessionPolicyRepository(),
          teacherRepository: FakeTeacherRepository(),
          marketConfigRepository: FakeMarketConfigRepository(),
        ),
        getTeacherProfile: GetTeacherProfileByIdUseCase(
          FakeTeacherProfileRepository(
            profile: TeacherProfile(
              id: 'teacher_1',
              userId: 'teacher_1',
              displayName: 'Teacher',
              verificationStatus: TeacherVerificationStatus.verified,
              teachingLanguages: const ['ar'],
              specializations: const ['tajweed'],
              averageRating: 0,
              reviewCount: 0,
              isActive: true,
              profileCompleteness: TeacherProfileCompletenessStatus.complete,
              isPubliclyVisible: true,
              externalMeetingUrl: 'https://meet.google.com/room',
              createdAt: DateTime.utc(2024, 1, 1),
              updatedAt: DateTime.utc(2024, 1, 2),
            ),
          ),
        ),
      ) {
    emit(seed);
  }

  @override
  void add(BookingEvent event) {}
}
