import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/auth/domain/services/callable_session_payload_builder.dart';
import 'package:tilawa/core/utils/legal_url_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/firebase/firebase_auth_session_provider.dart';
import '../data/firebase/firebase_audit_repository.dart';
import '../data/firebase/firebase_session_aggregate_repository.dart';
import '../data/firebase/firebase_session_command_gateway.dart';
import '../data/firebase/firebase_session_mutation_gateway.dart';
import '../data/firebase/firebase_session_notification_gateway.dart';
import '../data/firebase/firestore_availability_repository.dart';
import '../data/firebase/firestore_booking_repository.dart';
import '../data/firebase/firestore_market_config_repository.dart';
import '../data/firebase/firestore_market_scheduling_config_data_source.dart';
import '../data/firebase/firestore_schedule_repository.dart';
import '../data/firebase/firestore_session_policy_repository.dart';
import '../data/firebase/firestore_session_repository.dart';
import '../data/firebase/firestore_teacher_application_repository.dart';
import '../data/firebase/firestore_teacher_profile_repository.dart';
import '../data/firebase/firestore_teacher_repository.dart';
import '../data/firebase/firestore_user_profile_repository.dart';
import '../data/firebase/firestore_wallet_data_source.dart';
import '../data/shared_preferences_friday_review_reminder_store.dart';
import '../data/disabled_payment_provider.dart';
import '../data/sandbox_payment_provider.dart';
import 'quran_sessions_lifecycle_module.dart';
import 'quran_sessions_mvp_module.dart';

/// Wires Firestore-backed Quran Sessions repositories via [QuranSessionsModule].
class QuranSessionsFirebaseModule {
  QuranSessionsFirebaseModule._();

  static void register(GetIt sl, {AppLaunchConfig? launchConfig}) {
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

    final mutationGateway = FirebaseSessionMutationGateway(
      firestore,
      functions,
      sl<CallableSessionPayloadBuilder>(),
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
      teacherDataSource: FirestoreTeacherDataSource(firestore),
      sessionDataSource: FirestoreSessionDataSource(firestore),
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
      teacherApplicationDataSource: FirestoreTeacherApplicationDataSource(
        firestore,
      ),
      teacherProfileDataSource: FirestoreTeacherProfileDataSource(firestore),
      availabilityDataSource: FirestoreAvailabilityDataSource(firestore),
      scheduleDataSource: FirestoreScheduleDataSource(firestore),
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

    sl.registerLazySingletonIfAbsent<CallProvider>(
      () => ExternalMeetingCallProvider(
        getMeetingUrl: (sessionId) async {
          final result = await sl<SessionRepository>().getSessionById(
            sessionId,
          );
          return result.fold((_) => '', (session) => session.meetingLink ?? '');
        },
        urlLauncher: (url) async {
          final uri = Uri.tryParse(url);
          if (uri == null) {
            throw StateError('Invalid meeting URL');
          }
          final opened = await canLaunchUrl(uri)
              ? await launchUrl(uri, mode: LaunchMode.externalApplication)
              : await openLegalUrl(url);
          if (!opened) {
            throw StateError('Cannot open meeting URL');
          }
        },
      ),
    );

    QuranSessionsMvpModule.registerBlocs(sl);
  }
}
