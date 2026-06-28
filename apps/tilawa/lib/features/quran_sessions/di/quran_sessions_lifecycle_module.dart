import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';

/// Registers lifecycle domain services and use cases.
class QuranSessionsLifecycleModule {
  QuranSessionsLifecycleModule._();

  static void register(
    GetIt sl, {
    required SessionAggregateRepository aggregateRepository,
    required AuditRepository auditRepository,
    required SessionCommandGateway commandGateway,
    required SessionNotificationGateway notificationGateway,
    SessionMutationGateway? mutationGateway,
    AuthSessionProvider? authSession,
  }) {
    const lifecycleGuard = SessionLifecycleGuard();
    const cancellationPolicy = ConfigurableCancellationPolicy();
    const reschedulePolicy = ConfigurableReschedulePolicy();
    const bookingIntegrityValidator = BookingIntegrityValidator();
    const noShowPolicy = NoShowPolicy();

    sl.registerLazySingletonIfAbsent<SessionLifecycleGuard>(
      () => lifecycleGuard,
    );
    sl.registerLazySingletonIfAbsent<ConfigurableCancellationPolicy>(
      () => cancellationPolicy,
    );
    sl.registerLazySingletonIfAbsent<ConfigurableReschedulePolicy>(
      () => reschedulePolicy,
    );
    sl.registerLazySingletonIfAbsent<BookingIntegrityValidator>(
      () => bookingIntegrityValidator,
    );
    sl.registerLazySingletonIfAbsent<NoShowPolicy>(() => noShowPolicy);

    sl.registerLazySingletonIfAbsent<SessionAggregateRepository>(
      () => aggregateRepository,
    );
    sl.registerLazySingletonIfAbsent<AuditRepository>(
      () => auditRepository,
    );
    sl.registerLazySingletonIfAbsent<SessionNotificationGateway>(
      () => notificationGateway,
    );

    sl.registerLazySingletonIfAbsent<CancelSessionUseCase>(
      () => CancelSessionUseCase(
        aggregateRepository: sl<SessionAggregateRepository>(),
        lifecycleGuard: sl<SessionLifecycleGuard>(),
        cancellationPolicy: sl<ConfigurableCancellationPolicy>(),
        commandGateway: commandGateway,
        notificationGateway: sl<SessionNotificationGateway>(),
        auditRepository: sl<AuditRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent<RequestRescheduleUseCase>(
      () => RequestRescheduleUseCase(
        aggregateRepository: sl<SessionAggregateRepository>(),
        lifecycleGuard: sl<SessionLifecycleGuard>(),
        reschedulePolicy: sl<ConfigurableReschedulePolicy>(),
        notificationGateway: sl<SessionNotificationGateway>(),
        auditRepository: sl<AuditRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent<ConfirmRescheduleUseCase>(
      () => ConfirmRescheduleUseCase(
        aggregateRepository: sl<SessionAggregateRepository>(),
        lifecycleGuard: sl<SessionLifecycleGuard>(),
        commandGateway: commandGateway,
        notificationGateway: sl<SessionNotificationGateway>(),
        auditRepository: sl<AuditRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent<CompleteSessionUseCase>(
      () => CompleteSessionUseCase(
        aggregateRepository: sl<SessionAggregateRepository>(),
        lifecycleGuard: sl<SessionLifecycleGuard>(),
        auditRepository: sl<AuditRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent<MarkNoShowUseCase>(
      () => MarkNoShowUseCase(
        aggregateRepository: sl<SessionAggregateRepository>(),
        lifecycleGuard: sl<SessionLifecycleGuard>(),
        noShowPolicy: sl<NoShowPolicy>(),
        notificationGateway: sl<SessionNotificationGateway>(),
        auditRepository: sl<AuditRepository>(),
      ),
    );
    sl.registerLazySingletonIfAbsent<GetSessionTimelineUseCase>(
      () => GetSessionTimelineUseCase(sl<AuditRepository>()),
    );
    sl.registerLazySingletonIfAbsent<GetSessionAggregateUseCase>(
      () => GetSessionAggregateUseCase(sl<SessionAggregateRepository>()),
    );
    if (authSession != null) {
      sl.registerLazySingletonIfAbsent<ResolveSessionActorRoleUseCase>(
        () => ResolveSessionActorRoleUseCase(
          authSession: authSession,
          teacherProfileRepository: sl<TeacherProfileRepository>(),
        ),
      );
    }

    if (mutationGateway != null && authSession != null) {
      sl.registerLazySingletonIfAbsent<SessionMutationGateway>(
        () => mutationGateway,
      );
      sl.registerLazySingletonIfAbsent<SubmitSessionBookingUseCase>(
        () => SubmitSessionBookingUseCase(
          mutationGateway: mutationGateway,
          getAvailability: sl<GetTeacherAvailabilityUseCase>(),
          authSession: authSession,
          teacherProfiles: sl<TeacherProfileRepository>(),
        ),
      );
      sl.registerLazySingletonIfAbsent<
        RequestSessionRescheduleViaServerUseCase
      >(
        () => RequestSessionRescheduleViaServerUseCase(
          aggregateRepository: sl<SessionAggregateRepository>(),
          reschedulePolicy: sl<ConfigurableReschedulePolicy>(),
          mutationGateway: mutationGateway,
        ),
      );
      sl.registerLazySingletonIfAbsent<RespondToRescheduleRequestUseCase>(
        () => RespondToRescheduleRequestUseCase(
          mutationGateway: mutationGateway,
        ),
      );
      sl.registerLazySingletonIfAbsent<CancelSessionViaServerUseCase>(
        () => CancelSessionViaServerUseCase(
          cancelSession: sl<CancelSessionUseCase>(),
        ),
      );
      sl.registerLazySingletonIfAbsent<CompleteSessionViaServerUseCase>(
        () => CompleteSessionViaServerUseCase(
          mutationGateway: mutationGateway,
        ),
      );
      sl.registerLazySingletonIfAbsent<ReportSessionConcernUseCase>(
        () => ReportSessionConcernUseCase(gateway: mutationGateway),
      );
      sl.registerLazySingletonIfAbsent<OpenSessionDisputeUseCase>(
        () => OpenSessionDisputeUseCase(gateway: mutationGateway),
      );
      sl.registerLazySingletonIfAbsent<RespondToBookingRequestUseCase>(
        () => RespondToBookingRequestUseCase(mutationGateway),
      );
    }
  }
}
