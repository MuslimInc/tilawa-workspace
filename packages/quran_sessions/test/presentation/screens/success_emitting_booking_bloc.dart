import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_market_config_repository.dart';
import '../../helpers/fakes/fake_session_policy_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fakes/fake_user_profile_repository.dart';
import '../../helpers/lifecycle_test_helpers.dart';

/// [BookingBloc] fake that ignores events and lets tests emit
/// [BookingSuccess] on demand via [emitSuccess].
class SuccessEmittingBookingBloc extends BookingBloc {
  SuccessEmittingBookingBloc()
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
          FakeTeacherProfileRepository(),
        ),
      ) {
    emit(
      const BookingSelecting(teacherId: 'teacher_1', availableSlots: []),
    );
  }

  @override
  void add(BookingEvent event) {}

  void emitSuccess(QuranBooking booking) => emit(BookingSuccess(booking));
}
