import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/auth/domain/services/callable_session_payload_builder.dart';
import 'package:tilawa_core/services/performance_monitoring_service.dart';

import '../data/firebase/firebase_auth_session_provider.dart';
import '../data/firebase/firebase_audit_repository.dart';
import '../data/firebase/firebase_reschedule_request_repository.dart';
import '../data/firebase/firebase_session_aggregate_repository.dart';
import '../data/firebase/firebase_session_command_gateway.dart';
import '../data/firebase/firebase_session_mutation_gateway.dart';
import '../data/firebase/firebase_session_notification_gateway.dart';
import '../data/firebase/firestore_availability_repository.dart';
import '../data/firebase/firestore_booked_slot_lock_data_source.dart';
import '../data/firebase/firestore_booking_repository.dart';
import '../data/firebase/firestore_market_config_repository.dart';
import '../data/firebase/firestore_market_scheduling_config_data_source.dart';
import '../data/firebase/firestore_schedule_repository.dart';
import '../data/firebase/firestore_session_policy_repository.dart';
import '../data/firebase/firestore_session_repository.dart';
import '../data/firebase/firestore_teacher_application_access_data_source.dart';
import '../data/firebase/firestore_teacher_dashboard_summary_data_source.dart';
import '../data/firebase/firestore_teacher_application_repository.dart';
import '../data/firebase/firestore_teacher_profile_repository.dart';
import '../data/firebase/firestore_teacher_repository.dart';
import '../data/manual_payment_link_launcher.dart';
import '../data/firebase/firestore_user_profile_repository.dart';
import '../data/firebase/firestore_wallet_data_source.dart';
import '../data/shared_preferences_friday_review_reminder_store.dart';
import '../data/firebase/firebase_call_telemetry_gateway.dart';
import '../data/disabled_payment_provider.dart';
import '../data/sandbox_payment_provider.dart';
import 'quran_sessions_lifecycle_module.dart';
import 'quran_sessions_mvp_module.dart';
import 'quran_sessions_rtc_module.dart';

/// Wires Firestore-backed Quran Sessions repositories via [QuranSessionsModule].
class QuranSessionsFirebaseModule {
  QuranSessionsFirebaseModule._();

  static void register(GetIt sl, {AppLaunchConfig? launchConfig}) {
    registerManualPaymentLinkLauncher();
    final config =
        launchConfig ??
        (sl.isRegistered<AppLaunchConfig>()
            ? sl<AppLaunchConfig>()
            : AppLaunchConfig.fromEnvironment());
    final firestore = FirebaseFirestore.instance;
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    final authSession = FirebaseAuthSessionProvider(FirebaseAuth.instance);

    sl.registerLazySingletonIfAbsent<AuthSessionProvider>(() => authSession);
    sl.registerLazySingletonIfAbsent<SessionCommandGateway>(
      () => const FirebaseSessionCommandGateway(),
    );

    final sessionDataSource = FirestoreSessionDataSource(
      firestore,
      sl<PerformanceMonitoringService>(),
    );

    final mutationGateway = FirebaseSessionMutationGateway(
      firestore,
      functions,
      sl<CallableSessionPayloadBuilder>(),
      sl<PerformanceMonitoringService>(),
    );
    sl.registerLazySingletonIfAbsent<SessionMutationGateway>(
      () => mutationGateway,
    );

    final aggregateRepository = FirebaseSessionAggregateRepository(
      firestore,
      mutationGateway: mutationGateway,
    );
    final auditRepository = FirebaseAuditRepository(firestore);
    final notificationGateway = FirebaseSessionNotificationGateway(firestore);
    final rescheduleRequestRepository = FirebaseRescheduleRequestRepository(
      firestore,
    );

    sl.registerLazySingletonIfAbsent<RescheduleRequestRepository>(
      () => rescheduleRequestRepository,
    );
    sl.registerLazySingletonIfAbsent<GetPendingRescheduleRequestUseCase>(
      () => GetPendingRescheduleRequestUseCase(
        repository: rescheduleRequestRepository,
      ),
    );

    QuranSessionsLifecycleModule.register(
      sl,
      aggregateRepository: aggregateRepository,
      auditRepository: auditRepository,
      commandGateway: sl<SessionCommandGateway>(),
      notificationGateway: notificationGateway,
      mutationGateway: mutationGateway,
      authSession: authSession,
    );

    QuranSessionsModule.register(
      <T extends Object>(T instance, {String? instanceName}) {
        sl.registerSingletonOnce<T>(instance, instanceName: instanceName);
      },
      teacherDataSource: FirestoreTeacherDataSource(
        firestore,
        sl<PerformanceMonitoringService>(),
      ),
      sessionDataSource: sessionDataSource,
      bookingDataSource: FirestoreBookingDataSource(
        firestore,
        authSession,
        functions,
        sl<CallableSessionPayloadBuilder>(),
      ),
      userProfileDataSource: FirestoreUserProfileDataSource(firestore),
      marketConfigDataSource: FirestoreMarketConfigDataSource(firestore),
      marketSchedulingConfigDataSource:
          FirestoreMarketSchedulingConfigDataSource(firestore),
      sessionPolicyDataSource: FirestoreSessionPolicyDataSource(firestore),
      teacherApplicationAccessDataSource:
          FirestoreTeacherApplicationAccessDataSource(firestore),
      teacherApplicationDataSource: FirestoreTeacherApplicationDataSource(
        firestore,
      ),
      teacherProfileDataSource: FirestoreTeacherProfileDataSource(
        firestore,
        sl<PerformanceMonitoringService>(),
        sl<SharedPreferencesAsync>(),
      ),
      availabilityDataSource: FirestoreAvailabilityDataSource(firestore),
      bookedSlotLockDataSource: FirestoreBookedSlotLockDataSource(firestore),
      scheduleDataSource: FirestoreScheduleDataSource(
        firestore,
        sl<PerformanceMonitoringService>(),
      ),
      walletDataSource: FirestoreWalletDataSource(firestore),
      fridayReviewReminderStore: SharedPreferencesFridayReviewReminderStore(
        sl<SharedPreferencesAsync>(),
      ),
    );

    if (config.quranSessionsPaidBookingSandboxEnabled) {
      final sandbox = SandboxPaymentProvider(
        functions,
        sl<CallableSessionPayloadBuilder>(),
      );
      sl.registerLazySingletonIfAbsent<PaymentProvider>(() => sandbox);
      sl.registerLazySingletonIfAbsent<SessionPaymentConfirmation>(
        () => sandbox,
      );
    } else {
      sl.registerLazySingletonIfAbsent<PaymentProvider>(
        () => const DisabledPaymentProvider(),
      );
    }

    QuranSessionsRtcModule.register(sl, config);
    configureInAppCallShellCallSurface(
      QuranSessionsRtcModule.buildInAppCallSurfaceBuilder(sl),
    );

    sl.registerLazySingletonIfAbsent<SessionCallProviderEventHub>(
      () => SessionCallProviderEventHub(),
    );
    sl.registerLazySingletonIfAbsent<QuranSessionCallTelemetryGateway>(
      () => FirebaseCallTelemetryGateway(
        sl<CallableSessionPayloadBuilder>(),
        functions: functions,
      ),
    );
    sl.registerLazySingletonIfAbsent<QuranSessionCallTelemetryCoordinator>(
      () => QuranSessionCallTelemetryCoordinator(
        gateway: sl<QuranSessionCallTelemetryGateway>(),
        eventHub: sl<SessionCallProviderEventHub>(),
      ),
    );

    sl.registerLazySingletonIfAbsent<SessionCallProvider>(
      () => QuranSessionsRtcModule.buildRoutingProvider(sl, config),
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

    // One-read dashboard summary source. Registered only when the launch
    // flag is on; GetTeacherDashboardUseCase treats an absent registration as
    // "summary path disabled" and uses the legacy multi-fetch path.
    if (config.teacherDashboardSummaryReadEnabled) {
      sl.registerLazySingletonIfAbsent<TeacherDashboardSummarySource>(
        () => TeacherDashboardSummarySourceImpl(
          FirestoreTeacherDashboardSummaryDataSource(
            firestore,
            sl<PerformanceMonitoringService>(),
          ),
        ),
      );
    }

    // Application-layer caching use cases (GetTeacherDashboardUseCase,
    // InvalidateQuranSessionCacheUseCase, QuranSessionCacheStore, …) are only
    // registered here; the package module wires domain use cases alone.
    // registerUseCases is idempotent, so already-registered domain use cases
    // are skipped and only the caching layer is added.
    QuranSessionsMvpModule.registerUseCases(sl);
    QuranSessionsMvpModule.registerBlocs(sl);
  }
}
