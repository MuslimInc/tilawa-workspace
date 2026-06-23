import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';

import '../data/fake_auth_session_provider.dart';
import '../data/fake_mvp_availability_provider.dart';
import '../data/fake_mvp_booking_repository.dart';
import '../data/fake_mvp_market_config_repository.dart';
import '../data/fake_mvp_schedule_repository.dart';
import '../data/fake_mvp_session_policy_repository.dart';
import '../data/fake_mvp_session_repository.dart';
import '../data/fake_mvp_teacher_application_repository.dart';
import '../data/fake_mvp_teacher_profile_repository.dart';
import '../data/fake_mvp_teacher_repository.dart';
import '../data/fake_mvp_user_profile_repository.dart';
import '../data/fake_mvp_session_lifecycle.dart';
import '../data/quran_sessions_mvp_store.dart';
import '../presentation/quran_sessions_scheduling_analytics.dart';
import 'quran_sessions_lifecycle_module.dart';

/// Wires fake MVP repositories, boundaries, use cases, and BLoC factories
/// into [GetIt]. Call once after [configureDependencies].
class QuranSessionsMvpModule {
  QuranSessionsMvpModule._();

  static void register(GetIt sl) {
    final store = QuranSessionsMvpStore.instance;

    sl.registerLazySingletonIfAbsent<TeacherRepository>(
      () => FakeMvpTeacherRepository(store),
    );
    sl.registerLazySingletonIfAbsent<AuthSessionProvider>(
      () => const FakeAuthSessionProvider(userId: 'student_mvp'),
    );
    sl.registerLazySingletonIfAbsent<BookingRepository>(
      () => FakeMvpBookingRepository(store, sl<AuthSessionProvider>()),
    );
    sl.registerLazySingletonIfAbsent<SessionRepository>(
      () => FakeMvpSessionRepository(store),
    );
    sl.registerLazySingletonIfAbsent<AvailabilityProvider>(
      () => FakeMvpAvailabilityProvider(store),
    );
    sl.registerLazySingletonIfAbsent<UserProfileRepository>(
      () => FakeMvpUserProfileRepository(store),
    );
    sl.registerLazySingletonIfAbsent<SessionPolicyRepository>(
      () => FakeMvpSessionPolicyRepository(store),
    );
    sl.registerLazySingletonIfAbsent<MarketConfigRepository>(
      () => FakeMvpMarketConfigRepository(),
    );
    sl.registerLazySingletonIfAbsent<TeacherApplicationRepository>(
      () => FakeMvpTeacherApplicationRepository(store),
    );
    sl.registerLazySingletonIfAbsent<TeacherProfileRepository>(
      () => FakeMvpTeacherProfileRepository(store),
    );
    sl.registerLazySingletonIfAbsent<ScheduleRepository>(
      () => FakeMvpScheduleRepository(store),
    );

    sl.registerLazySingletonIfAbsent<MarketSchedulingConfigRepository>(
      () => MarketSchedulingConfigRepositoryImpl(
        const CatalogMarketSchedulingConfigRemoteDataSource(),
      ),
    );
    sl.registerLazySingletonIfAbsent<FridayReviewReminderStore>(
      () => InMemoryFridayReviewReminderStore(),
    );

    final lifecycle = FakeMvpSessionLifecycleStack.instance;
    sl.registerLazySingletonIfAbsent<SessionCommandGateway>(
      () => lifecycle.commandGateway,
    );
    sl.registerLazySingletonIfAbsent<SessionMutationGateway>(
      () => lifecycle.mutationGateway,
    );

    QuranSessionsLifecycleModule.register(
      sl,
      aggregateRepository: lifecycle.aggregateRepository,
      auditRepository: lifecycle.auditRepository,
      commandGateway: lifecycle.commandGateway,
      notificationGateway: lifecycle.notificationGateway,
      mutationGateway: lifecycle.mutationGateway,
      authSession: sl<AuthSessionProvider>(),
    );

    registerUseCases(sl);
    sl.registerLazySingletonIfAbsent<CallProvider>(
      () => ExternalMeetingCallProvider(
        getMeetingUrl: (sessionId) async {
          final result = await sl<SessionRepository>().getSessionById(
            sessionId,
          );
          return result.fold((_) => '', (session) => session.meetingLink ?? '');
        },
        urlLauncher: (_) async {},
      ),
    );
    registerBlocs(sl);
  }

  /// Registers use cases assuming repositories are already in [sl].
  static void registerUseCases(GetIt sl) {
    sl.registerLazySingletonIfAbsent(
      () => GetTeachersUseCase(sl<TeacherRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => GetTeacherProfileUseCase(sl<TeacherRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => GetTeacherAvailabilityUseCase(
        scheduleRepository: sl<ScheduleRepository>(),
        sessionRepository: sl<SessionRepository>(),
        slotGenerator: const SlotGenerator(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => GetStudentSessionsUseCase(sl<SessionRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => GetTeacherSessionsUseCase(sl<SessionRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => CreateBookingUseCase(
        sl<BookingRepository>(),
        sl<GetTeacherAvailabilityUseCase>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => CancelBookingUseCase(sl<BookingRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => SubmitReviewUseCase(sl<BookingRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => GetUserProfileUseCase(sl<UserProfileRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => CompleteStudentProfileUseCase(
        sl<UserProfileRepository>(),
        sl<SessionPolicyRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => CompleteTeacherProfileUseCase(
        sl<UserProfileRepository>(),
        sl<SessionPolicyRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => GetSessionPolicyUseCase(sl<SessionPolicyRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => UpdateTeacherEligibilityPolicyUseCase(
        sl<SessionPolicyRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => BlockAccountUseCase(sl<UserProfileRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => StartTeacherApplicationUseCase(sl<TeacherApplicationRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => SaveTeacherApplicationDraftUseCase(
        sl<TeacherApplicationRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => SubmitTeacherApplicationUseCase(sl<TeacherApplicationRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => GetTeacherApplicationStatusUseCase(
        sl<TeacherApplicationRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent<GetCurrentUserTeacherCapabilityUseCase>(
      () => GetCurrentUserTeacherCapabilityUseCase(
        applicationRepository: sl<TeacherApplicationRepository>(),
        profileRepository: sl<TeacherProfileRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => SaveTeacherPublicProfileUseCase(sl<TeacherProfileRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => ApproveTeacherApplicationUseCase(
        applicationRepository: sl<TeacherApplicationRepository>(),
        profileRepository: sl<TeacherProfileRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => RejectTeacherApplicationUseCase(sl<TeacherApplicationRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => SuspendTeacherProfileUseCase(
        applicationRepository: sl<TeacherApplicationRepository>(),
        profileRepository: sl<TeacherProfileRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => RevokeTeacherProfileUseCase(
        applicationRepository: sl<TeacherApplicationRepository>(),
        profileRepository: sl<TeacherProfileRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => GetMarketConfigUseCase(sl<MarketConfigRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => ValidateBookingEligibilityUseCase(
        profileRepository: sl<UserProfileRepository>(),
        policyRepository: sl<SessionPolicyRepository>(),
        teacherRepository: sl<TeacherRepository>(),
        marketConfigRepository: sl<MarketConfigRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(() => const WeeklyScheduleValidator());
    sl.registerLazySingletonIfAbsent(
      () => GetWeeklyScheduleUseCase(sl<ScheduleRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => SaveWeeklyScheduleUseCase(
        sl<ScheduleRepository>(),
        sl<WeeklyScheduleValidator>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => GetMarketSchedulingConfigUseCase(
        sl<MarketSchedulingConfigRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => BlockGeneratedSlotUseCase(sl<ScheduleRepository>()),
    );
  }

  /// Registers BLoC factories — new instance per navigation.
  static void registerBlocs(GetIt sl) {
    sl.registerFactoryIfAbsent(
      () => TeacherApplicationBloc(
        startApplication: sl<StartTeacherApplicationUseCase>(),
        saveDraft: sl<SaveTeacherApplicationDraftUseCase>(),
        submitApplication: sl<SubmitTeacherApplicationUseCase>(),
        getStatus: sl<GetTeacherApplicationStatusUseCase>(),
        approveApplication: sl<ApproveTeacherApplicationUseCase>(),
        getUserProfile: sl<GetUserProfileUseCase>(),
      ),
    );
    sl.registerFactoryIfAbsent(() => TeacherListBloc(sl<GetTeachersUseCase>()));
    sl.registerFactoryIfAbsent(
      () => TeacherProfileBloc(
        getProfile: sl<GetTeacherProfileUseCase>(),
        getAvailability: sl<GetTeacherAvailabilityUseCase>(),
      ),
    );
    sl.registerFactoryIfAbsent(
      () {
        final schedulingAnalytics = quranSessionsSchedulingAnalyticsCallbacks();
        return BookingBloc(
          getAvailability: sl<GetTeacherAvailabilityUseCase>(),
          submitBooking: sl<SubmitSessionBookingUseCase>(),
          validateEligibility: sl<ValidateBookingEligibilityUseCase>(),
          onBookingLostDueToNoAvailability:
              schedulingAnalytics.onBookingLostDueToNoAvailability,
          resolveMarketCode: (teacherId) async {
            final profile = await sl<GetUserProfileUseCase>()(teacherId);
            return profile.fold((_) => null, (value) => value.countryCode);
          },
        );
      },
    );
    sl.registerFactoryIfAbsent(
      () => MySessionsBloc(
        getStudentSessions: sl<GetStudentSessionsUseCase>(),
        cancelSession: sl<CancelSessionViaServerUseCase>(),
        submitReview: sl<SubmitReviewUseCase>(),
        callProvider: sl<CallProvider>(),
        studentId: sl<AuthSessionProvider>().currentUserId ?? 'student_mvp',
      ),
    );
    sl.registerFactoryIfAbsent(
      () => TeacherDashboardBloc(
        getTeacherSessions: sl<GetTeacherSessionsUseCase>(),
        getAvailability: sl<GetTeacherAvailabilityUseCase>(),
        blockGeneratedSlot: sl<BlockGeneratedSlotUseCase>(),
        availabilityProvider: sl<AvailabilityProvider>(),
        cancelSession: sl<CancelSessionViaServerUseCase>(),
        completeSession: sl<CompleteSessionViaServerUseCase>(),
        getMarketSchedulingConfig: sl<GetMarketSchedulingConfigUseCase>(),
        getUserProfile: sl<GetUserProfileUseCase>(),
        getWeeklySchedule: sl<GetWeeklyScheduleUseCase>(),
        fridayReviewReminderStore: sl<FridayReviewReminderStore>(),
        teacherId: sl<AuthSessionProvider>().currentUserId ?? 'teacher_mvp',
      ),
    );
    sl.registerFactoryIfAbsent(
      () => RescheduleBloc(
        getAvailability: sl<GetTeacherAvailabilityUseCase>(),
        requestReschedule: sl<RequestSessionRescheduleViaServerUseCase>(),
      ),
    );
    sl.registerFactoryIfAbsent(
      () => SessionDetailBloc(
        aggregateRepository: sl<SessionAggregateRepository>(),
        getTimeline: sl<GetSessionTimelineUseCase>(),
        callProvider: sl<CallProvider>(),
      ),
    );
    sl.registerFactoryIfAbsent(
      () => AvailabilityCubit(
        getSchedule: sl<GetWeeklyScheduleUseCase>(),
        saveSchedule: sl<SaveWeeklyScheduleUseCase>(),
        repository: sl<ScheduleRepository>(),
      ),
    );
    sl.registerFactoryIfAbsent(
      () => ProfileCompletionBloc(
        getUserProfile: sl<GetUserProfileUseCase>(),
        completeStudentProfile: sl<CompleteStudentProfileUseCase>(),
        getMarketConfig: sl<GetMarketConfigUseCase>(),
        getSessionPolicy: sl<GetSessionPolicyUseCase>(),
      ),
    );
  }
}
