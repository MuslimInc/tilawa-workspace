import '../data/datasources/availability_remote_data_source.dart';
import '../data/datasources/booked_slot_lock_remote_data_source.dart';
import '../data/datasources/booking_remote_data_source.dart';
import '../data/datasources/market_config_remote_data_source.dart';
import '../data/datasources/market_scheduling_config_remote_data_source.dart';
import '../data/datasources/schedule_remote_data_source.dart';
import '../data/datasources/session_policy_remote_data_source.dart';
import '../data/datasources/session_remote_data_source.dart';
import '../data/datasources/teacher_application_access_remote_data_source.dart';
import '../data/datasources/teacher_application_remote_data_source.dart';
import '../data/datasources/teacher_profile_remote_data_source.dart';
import '../data/datasources/teacher_remote_data_source.dart';
import '../data/datasources/user_profile_remote_data_source.dart';
import '../data/datasources/wallet_remote_data_source.dart';
import '../data/providers/remote_availability_provider.dart';
import '../data/repositories/booked_slot_lock_repository_impl.dart';
import '../data/repositories/booking_repository_impl.dart';
import '../data/repositories/market_config_repository_impl.dart';
import '../data/repositories/market_scheduling_config_repository_impl.dart';
import '../data/repositories/schedule_repository_impl.dart';
import '../data/repositories/session_policy_repository_impl.dart';
import '../data/repositories/session_repository_impl.dart';
import '../data/repositories/teacher_application_access_repository_impl.dart';
import '../data/repositories/teacher_application_repository_impl.dart';
import '../data/repositories/teacher_profile_repository_impl.dart';
import '../data/repositories/teacher_repository_impl.dart';
import '../data/repositories/user_profile_repository_impl.dart';
import '../data/repositories/wallet_repository_impl.dart';
import '../boundaries/scheduling/availability_provider.dart';
import '../boundaries/scheduling/friday_review_reminder_store.dart';
import '../data/stores/in_memory_friday_review_reminder_store.dart';
import '../domain/repositories/booked_slot_lock_repository.dart';
import '../domain/repositories/booking_repository.dart';
import '../domain/repositories/market_config_repository.dart';
import '../domain/repositories/market_scheduling_config_repository.dart';
import '../domain/repositories/schedule_repository.dart';
import '../domain/repositories/session_policy_repository.dart';
import '../domain/repositories/session_repository.dart';
import '../domain/repositories/teacher_application_access_repository.dart';
import '../domain/repositories/teacher_application_repository.dart';
import '../domain/repositories/teacher_profile_repository.dart';
import '../domain/repositories/teacher_repository.dart';
import '../domain/repositories/user_profile_repository.dart';
import '../domain/repositories/wallet_repository.dart';
import '../domain/usecases/approve_teacher_application_usecase.dart';
import '../domain/usecases/block_account_usecase.dart';
import '../domain/usecases/cancel_booking_usecase.dart';
import '../domain/usecases/complete_student_profile_usecase.dart';
import '../domain/usecases/complete_teacher_profile_usecase.dart';
import '../domain/usecases/create_booking_usecase.dart';
import '../domain/usecases/get_market_config_usecase.dart';
import '../domain/usecases/get_session_policy_usecase.dart';
import '../domain/usecases/get_student_sessions_usecase.dart';
import '../domain/usecases/get_current_user_teacher_capability_usecase.dart';
import '../domain/usecases/get_teacher_application_status_usecase.dart';
import '../domain/usecases/get_market_scheduling_config_usecase.dart';
import '../domain/usecases/get_teacher_availability_usecase.dart';
import '../domain/usecases/get_teacher_profile_usecase.dart';
import '../domain/usecases/get_teacher_sessions_usecase.dart';
import '../domain/usecases/is_slot_booked_usecase.dart';
import '../domain/usecases/get_teachers_usecase.dart';
import '../domain/usecases/get_user_profile_usecase.dart';
import '../domain/usecases/get_wallet_snapshot_usecase.dart';
import '../domain/usecases/resolve_teacher_application_access_usecase.dart';
import '../domain/usecases/reject_teacher_application_usecase.dart';
import '../domain/usecases/revoke_teacher_profile_usecase.dart';
import '../domain/usecases/save_teacher_application_draft_usecase.dart';
import '../domain/usecases/save_teacher_public_profile_usecase.dart';
import '../domain/usecases/update_teacher_meeting_link_usecase.dart';
import '../domain/usecases/start_teacher_application_usecase.dart';
import '../domain/usecases/submit_review_usecase.dart';
import '../domain/usecases/submit_teacher_application_usecase.dart';
import '../domain/usecases/suspend_teacher_profile_usecase.dart';
import '../domain/usecases/update_teacher_eligibility_policy_usecase.dart';
import '../domain/usecases/validate_booking_eligibility_usecase.dart';
import '../domain/usecases/block_generated_slot_usecase.dart';
import '../domain/usecases/get_weekly_schedule_usecase.dart';
import '../domain/usecases/save_weekly_schedule_usecase.dart';
import '../domain/services/weekly_schedule_validator.dart';
import '../domain/services/slot_generator.dart';

/// Registration helper for the `quran_sessions` package.
///
/// Call [QuranSessionsModule.register] in the host app's DI setup,
/// supplying remote datasource implementations. Firebase code lives only in
/// the host app — this module wires backend-agnostic repositories and use
/// cases.
class QuranSessionsModule {
  QuranSessionsModule._();

  /// Registers repositories and use cases into [registerSingleton].
  static void register(
    void Function<T extends Object>(T instance, {String? instanceName})
    registerSingleton, {
    required TeacherRemoteDataSource teacherDataSource,
    required SessionRemoteDataSource sessionDataSource,
    required BookingRemoteDataSource bookingDataSource,
    required UserProfileRemoteDataSource userProfileDataSource,
    required MarketConfigRemoteDataSource marketConfigDataSource,
    required MarketSchedulingConfigRemoteDataSource
    marketSchedulingConfigDataSource,
    required SessionPolicyRemoteDataSource sessionPolicyDataSource,
    required TeacherApplicationAccessRemoteDataSource
    teacherApplicationAccessDataSource,
    required TeacherApplicationRemoteDataSource teacherApplicationDataSource,
    required TeacherProfileRemoteDataSource teacherProfileDataSource,
    required AvailabilityRemoteDataSource availabilityDataSource,
    required BookedSlotLockRemoteDataSource bookedSlotLockDataSource,
    required ScheduleRemoteDataSource scheduleDataSource,
    required WalletRemoteDataSource walletDataSource,
    FridayReviewReminderStore? fridayReviewReminderStore,
  }) {
    final teacherRepo = TeacherRepositoryImpl(teacherDataSource);
    final sessionRepo = SessionRepositoryImpl(sessionDataSource);
    final bookingRepo = BookingRepositoryImpl(bookingDataSource);
    final profileRepo = UserProfileRepositoryImpl(userProfileDataSource);
    final marketConfigRepo = MarketConfigRepositoryImpl(marketConfigDataSource);
    final marketSchedulingConfigRepo = MarketSchedulingConfigRepositoryImpl(
      marketSchedulingConfigDataSource,
    );
    final policyRepo = SessionPolicyRepositoryImpl(sessionPolicyDataSource);
    final teacherApplicationAccessRepo = TeacherApplicationAccessRepositoryImpl(
      teacherApplicationAccessDataSource,
    );
    final applicationRepo = TeacherApplicationRepositoryImpl(
      teacherApplicationDataSource,
    );
    final teacherProfileRepo = TeacherProfileRepositoryImpl(
      teacherProfileDataSource,
    );
    final availabilityProvider = RemoteAvailabilityProvider(
      availabilityDataSource,
    );
    final scheduleRepo = ScheduleRepositoryImpl(
      scheduleDataSource,
      teacherProfiles: teacherProfileRepo,
    );
    final bookedSlotLockRepo = BookedSlotLockRepositoryImpl(
      bookedSlotLockDataSource,
      teacherProfiles: teacherProfileRepo,
    );
    final walletRepo = WalletRepositoryImpl(walletDataSource);

    registerSingleton<TeacherRepository>(teacherRepo);
    registerSingleton<SessionRepository>(sessionRepo);
    registerSingleton<BookingRepository>(bookingRepo);
    registerSingleton<UserProfileRepository>(profileRepo);
    registerSingleton<MarketConfigRepository>(marketConfigRepo);
    registerSingleton<MarketSchedulingConfigRepository>(
      marketSchedulingConfigRepo,
    );
    registerSingleton<SessionPolicyRepository>(policyRepo);
    registerSingleton<TeacherApplicationAccessRepository>(
      teacherApplicationAccessRepo,
    );
    registerSingleton<TeacherApplicationRepository>(applicationRepo);
    registerSingleton<TeacherProfileRepository>(teacherProfileRepo);
    registerSingleton<AvailabilityProvider>(availabilityProvider);
    registerSingleton<ScheduleRepository>(scheduleRepo);
    registerSingleton<BookedSlotLockRepository>(bookedSlotLockRepo);
    registerSingleton<WalletRepository>(walletRepo);

    registerSingleton(GetTeachersUseCase(teacherRepo));
    registerSingleton(GetTeacherProfileUseCase(teacherRepo));
    const slotGenerator = SlotGenerator();
    registerSingleton(slotGenerator);
    final getTeacherAvailability = GetTeacherAvailabilityUseCase(
      scheduleRepository: scheduleRepo,
      bookedSlotLocks: bookedSlotLockRepo,
      slotGenerator: slotGenerator,
    );
    registerSingleton(getTeacherAvailability);
    registerSingleton(GetTeacherSessionsUseCase(sessionRepo));
    registerSingleton(GetStudentSessionsUseCase(sessionRepo));
    registerSingleton(IsSlotBookedUseCase(bookedSlotLockRepo));
    registerSingleton(
      CreateBookingUseCase(bookingRepo, getTeacherAvailability),
    );
    registerSingleton(CancelBookingUseCase(bookingRepo));
    registerSingleton(SubmitReviewUseCase(bookingRepo));
    registerSingleton(GetUserProfileUseCase(profileRepo));
    registerSingleton(GetWalletSnapshotUseCase(walletRepo));
    registerSingleton(CompleteStudentProfileUseCase(profileRepo, policyRepo));
    registerSingleton(CompleteTeacherProfileUseCase(profileRepo, policyRepo));
    registerSingleton(GetSessionPolicyUseCase(policyRepo));
    registerSingleton(UpdateTeacherEligibilityPolicyUseCase(policyRepo));
    registerSingleton(BlockAccountUseCase(profileRepo));
    registerSingleton(StartTeacherApplicationUseCase(applicationRepo));
    registerSingleton(SaveTeacherApplicationDraftUseCase(applicationRepo));
    registerSingleton(SubmitTeacherApplicationUseCase(applicationRepo));
    registerSingleton(GetTeacherApplicationStatusUseCase(applicationRepo));
    registerSingleton(
      ResolveTeacherApplicationAccessUseCase(teacherApplicationAccessRepo),
    );
    registerSingleton<GetCurrentUserTeacherCapabilityUseCase>(
      GetCurrentUserTeacherCapabilityUseCase(
        applicationRepository: applicationRepo,
        profileRepository: teacherProfileRepo,
      ),
    );
    registerSingleton(
      SaveTeacherPublicProfileUseCase(teacherProfileRepo),
    );
    registerSingleton(
      UpdateTeacherMeetingLinkUseCase(teacherProfileRepo),
    );
    registerSingleton(
      ApproveTeacherApplicationUseCase(
        applicationRepository: applicationRepo,
        profileRepository: teacherProfileRepo,
      ),
    );
    registerSingleton(RejectTeacherApplicationUseCase(applicationRepo));
    registerSingleton(
      SuspendTeacherProfileUseCase(
        applicationRepository: applicationRepo,
        profileRepository: teacherProfileRepo,
      ),
    );
    registerSingleton(
      RevokeTeacherProfileUseCase(
        applicationRepository: applicationRepo,
        profileRepository: teacherProfileRepo,
      ),
    );
    registerSingleton(GetMarketConfigUseCase(marketConfigRepo));
    registerSingleton(
      GetMarketSchedulingConfigUseCase(marketSchedulingConfigRepo),
    );
    registerSingleton<FridayReviewReminderStore>(
      fridayReviewReminderStore ?? InMemoryFridayReviewReminderStore(),
    );
    registerSingleton(
      ValidateBookingEligibilityUseCase(
        profileRepository: profileRepo,
        policyRepository: policyRepo,
        teacherRepository: teacherRepo,
        marketConfigRepository: marketConfigRepo,
      ),
    );
    const scheduleValidator = WeeklyScheduleValidator();
    registerSingleton(scheduleValidator);
    registerSingleton(GetWeeklyScheduleUseCase(scheduleRepo));
    registerSingleton(
      SaveWeeklyScheduleUseCase(scheduleRepo, scheduleValidator),
    );
    registerSingleton(BlockGeneratedSlotUseCase(scheduleRepo));
  }
}
