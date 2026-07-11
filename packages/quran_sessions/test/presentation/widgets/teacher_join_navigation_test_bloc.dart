import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/fakes/fake_user_profile_repository.dart';
import '../../helpers/lifecycle_test_helpers.dart';

/// Seeds [TeacherDashboardBloc] and resolves join requests immediately so
/// join navigation can be asserted without a real call provider round-trip.
class TeacherJoinNavigationTestBloc extends TeacherDashboardBloc {
  TeacherJoinNavigationTestBloc({
    required TeacherDashboardSuccess seed,
    required FakeSessionRepository sessionRepo,
    required FakeScheduleRepository scheduleRepo,
  }) : super(
         getTeacherDashboard: GetTeacherDashboardUseCase(
           userProfileRepository: FakeUserProfileRepository(),
           marketSchedulingConfigRepository:
               FakeMarketSchedulingConfigRepository(),
           scheduleRepository: scheduleRepo,
           sessionRepository: sessionRepo,
           teacherProfileRepository: FakeTeacherProfileRepository(),
           getTeacherAvailability: SpyGetTeacherAvailabilityUseCase(
             scheduleRepository: scheduleRepo,
             bookedSlotLocks: FakeBookedSlotLockRepository(),
           ),
           cacheStore: MemoryCacheStore(),
         ),
         invalidateCache: InvalidateQuranSessionCacheUseCase(
           MemoryCacheStore(),
         ),
         isSlotBooked: IsSlotBookedUseCase(
           FakeBookedSlotLockRepository(),
         ),
         getAvailability: SpyGetTeacherAvailabilityUseCase(
           scheduleRepository: scheduleRepo,
           bookedSlotLocks: FakeBookedSlotLockRepository(),
         ),
         blockGeneratedSlot: BlockGeneratedSlotUseCase(scheduleRepo),
         availabilityProvider: FakeAvailabilityProvider(),
         cancelSession: buildCancelSessionViaServerUseCase(),
         respondToBookingRequest: buildRespondToBookingRequestUseCase(),
         completeSession: buildCompleteSessionViaServerUseCase(),
         joinSession: buildJoinSessionUseCase(
           sessionRepository: sessionRepo,
           userId: 'teacher_1',
         ),
         fridayReviewReminderStore: InMemoryFridayReviewReminderStore(),
         teacherId: 'teacher_1',
       ) {
    emit(seed);
  }

  @override
  void add(TeacherDashboardEvent event) {
    if (event is TeacherDashboardLoadRequested) {
      return;
    }
    if (event is TeacherDashboardSessionJoinRequested) {
      final current = state;
      if (current is! TeacherDashboardSuccess) {
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
    if (event is TeacherDashboardJoinCompletedAcknowledged) {
      final current = state;
      if (current is! TeacherDashboardSuccess) {
        return;
      }
      emit(current.copyWith(clearJoinCompletedSessionId: true));
      return;
    }
    super.add(event);
  }
}
