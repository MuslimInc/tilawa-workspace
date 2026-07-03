import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_launch_policy.dart';
import 'package:tilawa_core/network/network_info.dart';

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
import '../data/fake_mvp_wallet_repository.dart';
import '../data/fake_mvp_session_lifecycle.dart';
import '../data/external_meeting_url_launcher.dart';
import '../data/manual_payment_link_launcher.dart';
import '../data/quran_sessions_mvp_store.dart';
import '../data/session_backed_booked_slot_lock_repository.dart';
import '../presentation/quran_sessions_scheduling_analytics.dart';
import 'quran_sessions_lifecycle_module.dart';

/// **NON-PRODUCTION ONLY** — wires in-memory fake repositories for local UI dev.
///
/// Never register this module in release builds. Production uses
/// [QuranSessionsFirebaseModule] with Firestore + Cloud Functions.
/// See `docs/quran-sessions/domain-audit-report.md`.
class QuranSessionsMvpModule {
  QuranSessionsMvpModule._();

  static void register(GetIt sl) {
    registerManualPaymentLinkLauncher();
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
    sl.registerLazySingletonIfAbsent<BookedSlotLockRepository>(
      () => SessionBackedBookedSlotLockRepository(sl<SessionRepository>()),
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
    sl.registerLazySingletonIfAbsent<TeacherApplicationAccessRepository>(
      () => TeacherApplicationAccessRepositoryImpl(
        const CatalogTeacherApplicationAccessRemoteDataSource(
          policy: TeacherApplicationAccessPolicyDto(mode: 'all'),
        ),
      ),
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
    sl.registerLazySingletonIfAbsent<WalletRepository>(
      () => const FakeMvpWalletRepository(),
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
    sl.registerLazySingletonIfAbsent<SessionCallProviderEventHub>(
      () => SessionCallProviderEventHub(),
    );
    sl.registerLazySingletonIfAbsent<QuranSessionCallTelemetryGateway>(
      () => InMemoryCallTelemetryGateway(),
    );
    sl.registerLazySingletonIfAbsent<QuranSessionCallTelemetryCoordinator>(
      () => QuranSessionCallTelemetryCoordinator(
        gateway: sl<QuranSessionCallTelemetryGateway>(),
        eventHub: sl<SessionCallProviderEventHub>(),
      ),
    );

    sl.registerLazySingletonIfAbsent<SessionCallProvider>(
      () => RoutingSessionCallProvider(
        external: ExternalMeetingCallProvider(
          getMeetingUrl: (sessionId) async {
            final result = await sl<SessionRepository>().getSessionById(
              sessionId,
            );
            return result.fold(
              (_) => '',
              (session) => session.joinUrl ?? '',
            );
          },
          urlLauncher: (_) async {},
        ),
        mock: MockSessionCallProvider(
          eventHub: sl<SessionCallProviderEventHub>(),
        ),
      ),
    );
    sl.registerLazySingletonIfAbsent<CallProvider>(
      () => CallProviderAdapter(sl<SessionCallProvider>()),
    );
    sl.registerLazySingletonIfAbsent<JoinSessionUseCase>(
      () => JoinSessionUseCase(
        sessionRepository: sl<SessionRepository>(),
        callProvider: sl<SessionCallProvider>(),
        authSession: sl<AuthSessionProvider>(),
        teacherProfileRepository: sl<TeacherProfileRepository>(),
        callTelemetry: sl<QuranSessionCallTelemetryCoordinator>(),
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
        bookedSlotLocks: sl<BookedSlotLockRepository>(),
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
      () => IsSlotBookedUseCase(sl<BookedSlotLockRepository>()),
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
      () => GetWalletSnapshotUseCase(sl<WalletRepository>()),
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
      () => ResolveTeacherApplicationAccessUseCase(
        sl<TeacherApplicationAccessRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => SaveTeacherPublicProfileUseCase(sl<TeacherProfileRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => UpdateTeacherMeetingLinkUseCase(sl<TeacherProfileRepository>()),
    );
    sl.registerLazySingletonIfAbsent(
      () => GetTeacherProfileByIdUseCase(sl<TeacherProfileRepository>()),
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

    // ── Application-layer caching use cases ──────────────────────────────────
    sl.registerLazySingletonIfAbsent<QuranSessionCacheStore>(
      () => MemoryCacheStore(),
    );
    sl.registerLazySingletonIfAbsent(
      () => GetTeacherDashboardUseCase(
        userProfileRepository: sl<UserProfileRepository>(),
        marketSchedulingConfigRepository:
            sl<MarketSchedulingConfigRepository>(),
        scheduleRepository: sl<ScheduleRepository>(),
        sessionRepository: sl<SessionRepository>(),
        teacherProfileRepository: sl<TeacherProfileRepository>(),
        getTeacherAvailability: sl<GetTeacherAvailabilityUseCase>(),
        cacheStore: sl<QuranSessionCacheStore>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => RefreshTeacherDashboardUseCase(
        sl<GetTeacherDashboardUseCase>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => GetSessionDetailUseCase(
        sessionRepository: sl<SessionRepository>(),
        cacheStore: sl<QuranSessionCacheStore>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => RefreshSessionDetailUseCase(
        getSessionDetail: sl<GetSessionDetailUseCase>(),
        cacheStore: sl<QuranSessionCacheStore>(),
      ),
    );
    sl.registerLazySingletonIfAbsent(
      () => InvalidateQuranSessionCacheUseCase(
        sl<QuranSessionCacheStore>(),
      ),
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
    sl.registerFactoryIfAbsent(
      () => TeacherListBloc(
        sl<GetTeachersUseCase>(),
        sl<GetTeacherAvailabilityUseCase>(),
      ),
    );
    sl.registerFactoryIfAbsent(
      () => TeacherProfileBloc(
        getProfile: sl<GetTeacherProfileUseCase>(),
        getAvailability: sl<GetTeacherAvailabilityUseCase>(),
        reportConcern: sl.isRegistered<ReportSessionConcernUseCase>()
            ? sl<ReportSessionConcernUseCase>()
            : null,
      ),
    );
    sl.registerFactoryIfAbsent(
      () {
        final schedulingAnalytics = quranSessionsSchedulingAnalyticsCallbacks();
        final launchConfig = sl<AppLaunchConfig>();
        return BookingBloc(
          getAvailability: sl<GetTeacherAvailabilityUseCase>(),
          submitBooking: sl<SubmitSessionBookingUseCase>(),
          validateEligibility: sl<ValidateBookingEligibilityUseCase>(),
          getTeacherProfile: sl<GetTeacherProfileByIdUseCase>(),
          getTeacherListing: sl<GetTeacherProfileUseCase>(),
          getUserProfile: sl<GetUserProfileUseCase>(),
          getMarketConfig: sl<GetMarketConfigUseCase>(),
          sessionModePolicy: sessionModePolicyFromLaunchConfig(launchConfig),
          paymentConfirmation: sl.isRegistered<SessionPaymentConfirmation>()
              ? sl<SessionPaymentConfirmation>()
              : null,
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
        joinSession: sl<JoinSessionUseCase>(),
        studentId: sl<AuthSessionProvider>().currentUserId ?? 'student_mvp',
      ),
    );
    sl.registerFactoryIfAbsent(
      () => TeacherDashboardBloc(
        dashboardUseCase: sl<GetTeacherDashboardUseCase>(),
        cacheInvalidator: sl<InvalidateQuranSessionCacheUseCase>(),
        slotBookedUseCase: sl<IsSlotBookedUseCase>(),
        availabilityUseCase: sl<GetTeacherAvailabilityUseCase>(),
        blockSlotUseCase: sl<BlockGeneratedSlotUseCase>(),
        availabilityGateway: sl<AvailabilityProvider>(),
        cancelSessionUseCase: sl<CancelSessionViaServerUseCase>(),
        respondToBookingRequestUseCase: sl<RespondToBookingRequestUseCase>(),
        completeSessionUseCase: sl<CompleteSessionViaServerUseCase>(),
        fridayReminderStore: sl<FridayReviewReminderStore>(),
        teacherUserId: sl<AuthSessionProvider>().currentUserId ?? 'teacher_mvp',
        isConnected: sl.isRegistered<NetworkInfo>()
            ? () => sl<NetworkInfo>().isConnected
            : null,
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
        getSessionAggregate: sl<GetSessionAggregateUseCase>(),
        getTimeline: sl<GetSessionTimelineUseCase>(),
        sessionDetailUseCase: sl.isRegistered<GetSessionDetailUseCase>()
            ? sl<GetSessionDetailUseCase>()
            : null,
        cacheInvalidator: sl.isRegistered<InvalidateQuranSessionCacheUseCase>()
            ? sl<InvalidateQuranSessionCacheUseCase>()
            : null,
        sessionRepository: sl<SessionRepository>(),
        joinSession: sl<JoinSessionUseCase>(),
        openExternalMeetingUrl: launchExternalMeetingUrl,
        reportConcern: sl.isRegistered<ReportSessionConcernUseCase>()
            ? sl<ReportSessionConcernUseCase>()
            : null,
        openDispute: sl.isRegistered<OpenSessionDisputeUseCase>()
            ? sl<OpenSessionDisputeUseCase>()
            : null,
        submitReview: sl.isRegistered<SubmitReviewUseCase>()
            ? sl<SubmitReviewUseCase>()
            : null,
        getPendingReschedule:
            sl.isRegistered<GetPendingRescheduleRequestUseCase>()
            ? sl<GetPendingRescheduleRequestUseCase>()
            : null,
        respondToReschedule:
            sl.isRegistered<RespondToRescheduleRequestUseCase>()
            ? sl<RespondToRescheduleRequestUseCase>()
            : null,
        cancelSession: sl.isRegistered<CancelSessionViaServerUseCase>()
            ? sl<CancelSessionViaServerUseCase>()
            : null,
        authSession: sl.isRegistered<AuthSessionProvider>()
            ? sl<AuthSessionProvider>()
            : null,
        resolveActorRole: sl.isRegistered<ResolveSessionActorRoleUseCase>()
            ? sl<ResolveSessionActorRoleUseCase>()
            : null,
        tokenProvider: sl.isRegistered<CallTokenProvider>()
            ? sl<CallTokenProvider>()
            : null,
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
      () => WalletBloc(getWalletSnapshot: sl<GetWalletSnapshotUseCase>()),
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
