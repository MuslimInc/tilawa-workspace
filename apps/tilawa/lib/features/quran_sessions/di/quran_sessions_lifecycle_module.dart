import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';

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

    sl.registerLazySingleton<SessionLifecycleGuard>(() => lifecycleGuard);
    sl.registerLazySingleton<ConfigurableCancellationPolicy>(
      () => cancellationPolicy,
    );
    sl.registerLazySingleton<ConfigurableReschedulePolicy>(
      () => reschedulePolicy,
    );
    sl.registerLazySingleton<BookingIntegrityValidator>(
      () => bookingIntegrityValidator,
    );
    sl.registerLazySingleton<NoShowPolicy>(() => noShowPolicy);

    sl.registerLazySingleton<SessionAggregateRepository>(
      () => aggregateRepository,
    );
    sl.registerLazySingleton<AuditRepository>(() => auditRepository);
    sl.registerLazySingleton<SessionNotificationGateway>(
      () => notificationGateway,
    );

    sl.registerLazySingleton(
      () => CancelSessionUseCase(
        aggregateRepository: sl<SessionAggregateRepository>(),
        lifecycleGuard: sl<SessionLifecycleGuard>(),
        cancellationPolicy: sl<ConfigurableCancellationPolicy>(),
        commandGateway: commandGateway,
        notificationGateway: sl<SessionNotificationGateway>(),
        auditRepository: sl<AuditRepository>(),
      ),
    );
    sl.registerLazySingleton(
      () => RequestRescheduleUseCase(
        aggregateRepository: sl<SessionAggregateRepository>(),
        lifecycleGuard: sl<SessionLifecycleGuard>(),
        reschedulePolicy: sl<ConfigurableReschedulePolicy>(),
        notificationGateway: sl<SessionNotificationGateway>(),
        auditRepository: sl<AuditRepository>(),
      ),
    );
    sl.registerLazySingleton(
      () => ConfirmRescheduleUseCase(
        aggregateRepository: sl<SessionAggregateRepository>(),
        lifecycleGuard: sl<SessionLifecycleGuard>(),
        commandGateway: commandGateway,
        notificationGateway: sl<SessionNotificationGateway>(),
        auditRepository: sl<AuditRepository>(),
      ),
    );
    sl.registerLazySingleton(
      () => CompleteSessionUseCase(
        aggregateRepository: sl<SessionAggregateRepository>(),
        lifecycleGuard: sl<SessionLifecycleGuard>(),
        auditRepository: sl<AuditRepository>(),
      ),
    );
    sl.registerLazySingleton(
      () => MarkNoShowUseCase(
        aggregateRepository: sl<SessionAggregateRepository>(),
        lifecycleGuard: sl<SessionLifecycleGuard>(),
        noShowPolicy: sl<NoShowPolicy>(),
        notificationGateway: sl<SessionNotificationGateway>(),
        auditRepository: sl<AuditRepository>(),
      ),
    );
    sl.registerLazySingleton(
      () => GetSessionTimelineUseCase(sl<AuditRepository>()),
    );

    if (mutationGateway != null && authSession != null) {
      sl.registerLazySingleton<SessionMutationGateway>(
        () => mutationGateway,
      );
      sl.registerLazySingleton(
        () => SubmitSessionBookingUseCase(
          mutationGateway: mutationGateway,
          getAvailability: sl<GetTeacherAvailabilityUseCase>(),
          authSession: authSession,
        ),
      );
      sl.registerLazySingleton(
        () => RequestSessionRescheduleViaServerUseCase(
          aggregateRepository: sl<SessionAggregateRepository>(),
          reschedulePolicy: sl<ConfigurableReschedulePolicy>(),
          mutationGateway: mutationGateway,
        ),
      );
      sl.registerLazySingleton(
        () => RespondToRescheduleRequestUseCase(
          mutationGateway: mutationGateway,
        ),
      );
      sl.registerLazySingleton(
        () => CancelSessionViaServerUseCase(
          cancelSession: sl<CancelSessionUseCase>(),
        ),
      );
      sl.registerLazySingleton(
        () => CompleteSessionViaServerUseCase(
          mutationGateway: mutationGateway,
        ),
      );
    }
  }
}
