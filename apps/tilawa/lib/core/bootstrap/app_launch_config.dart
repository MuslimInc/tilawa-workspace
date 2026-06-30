import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Launch-time feature toggles for startup orchestration.
///
/// Most toggles default to enabled and can be overridden via `--dart-define`.
/// [subscriptionServiceEnabled] defaults to **false** so subscription
/// Firestore usage in `SubscriptionPlansService` (catalog, premium status,
/// purchase records) stays off until explicitly enabled.
///
/// [supportTilawaEnabled] defaults to **true** (Settings/Profile Support entry).
///
/// Example: `--dart-define=TILAWA_LAUNCH_FIREBASE_INIT=false`
/// Example: `--dart-define=TILAWA_LAUNCH_SUBSCRIPTION_SERVICE_ENABLED=true`
/// Example: `--dart-define=TILAWA_LAUNCH_SUPPORT_TILAWA_ENABLED=false`
/// Example: `--dart-define=TILAWA_LAUNCH_RECITATION_PRACTICE_ENABLED=true`
/// Example: `--dart-define=TILAWA_LAUNCH_SMART_KHATMA_ENABLED=true`
/// Example: `--dart-define=TILAWA_LAUNCH_TODAY_PLAN_ENABLED=true`
/// Example: `--dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=true`
/// Example: `--dart-define=TILAWA_LAUNCH_TEACHER_APPLICATION_ENABLED=true`
/// Example: `--dart-define=TILAWA_LAUNCH_TEACHER_APPLICATION_DISCOVERABILITY=profileAndEmptyState`
/// Example: `--dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true`
/// Example: `--dart-define=TILAWA_LAUNCH_QURAN_TUTOR_BOOKING_MODE=autoConfirm`
/// Example: `--dart-define=TILAWA_LAUNCH_QURAN_TUTOR_BOOKING_MODE=requiresTutorApproval`
/// Example: `--dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock,livekit`
/// Example: `--dart-define=TILAWA_LAUNCH_AGORA_APP_ID=your_agora_app_id`
/// Example: `--dart-define=TILAWA_LAUNCH_LIVEKIT_URL=wss://tilawa-7whzug8z.livekit.cloud`
///
/// Staging / pre-production builds default QuranTutor beta flags ON via
/// [quranSessionsStagingFlagsDefaultEnabled] (everything except
/// `play_production`). Override per flag with `TILAWA_LAUNCH_*` dart-defines.
bool quranSessionsStagingFlagsDefaultEnabled() {
  const distribution = String.fromEnvironment(
    'TILAWA_DISTRIBUTION',
    defaultValue: 'local',
  );
  return distribution != 'play_production';
}

@immutable
class AppLaunchConfig extends Equatable {
  const AppLaunchConfig({
    this.resetLaunchState = true,
    this.frameWatcher = true,
    this.perfInstrumentation = kProfileMode,
    this.firebaseInit = true,
    this.hydratedStorageInit = true,
    this.foregroundMessaging = true,
    this.blocObserver = false,
    this.notificationLaunchProbe = true,
    this.systemChrome = true,
    this.nonCriticalServices = true,
    this.deferredNotificationChannel = true,
    this.crashlyticsInit = true,
    this.hiveInit = true,
    this.analyticsInit = true,
    this.notificationServiceInit = true,
    this.notificationHandlersInit = true,
    this.athkarNotificationsInit = true,
    this.prayerNotificationsInit = true,
    this.downloadsInit = true,
    this.audioServiceInit = true,
    this.quranDataLoad = true,
    this.quranAssetsPrefetch = true,
    this.firebaseDataInit = true,
    this.subscriptionServiceEnabled = false,
    this.supportTilawaEnabled = true,
    this.recitationPracticeEnabled = false,
    this.smartKhatmaEnabled = false,
    this.todayPlanEnabled = false,
    this.notificationPermissionRequest = true,
    this.quranSessionsEnabled = true,
    this.teacherApplicationEnabled = false,
    this.teacherApplicationDiscoverability = 'profileAndEmptyState',
    this.quranSessionsBookingEnabled = false,
    this.quranSessionsPaidBookingSandboxEnabled = false,
    this.enabledCallProvidersCsv = 'external,mock',
    this.agoraAppId = '',
    this.livekitServerUrl = '',
    this.genUiAssistantEnabled = false,
  });

  factory AppLaunchConfig.fromEnvironment() {
    const distribution = String.fromEnvironment(
      'TILAWA_DISTRIBUTION',
      defaultValue: 'local',
    );
    const stagingFlagsOn = distribution != 'play_production';
    return AppLaunchConfig(
      resetLaunchState: bool.fromEnvironment(
        'TILAWA_LAUNCH_RESET_LAUNCH_STATE',
        defaultValue: true,
      ),
      frameWatcher: bool.fromEnvironment(
        'TILAWA_LAUNCH_FRAME_WATCHER',
        defaultValue: true,
      ),
      perfInstrumentation: bool.fromEnvironment(
        'TILAWA_LAUNCH_PERF_INSTRUMENTATION',
        defaultValue: kProfileMode,
      ),
      firebaseInit: bool.fromEnvironment(
        'TILAWA_LAUNCH_FIREBASE_INIT',
        defaultValue: true,
      ),
      hydratedStorageInit: bool.fromEnvironment(
        'TILAWA_LAUNCH_HYDRATED_STORAGE_INIT',
        defaultValue: true,
      ),
      foregroundMessaging: bool.fromEnvironment(
        'TILAWA_LAUNCH_FOREGROUND_MESSAGING',
        defaultValue: true,
      ),
      blocObserver: bool.fromEnvironment(
        'TILAWA_LAUNCH_BLOC_OBSERVER',
        defaultValue: false,
      ),
      notificationLaunchProbe: bool.fromEnvironment(
        'TILAWA_LAUNCH_NOTIFICATION_LAUNCH_PROBE',
        defaultValue: true,
      ),
      systemChrome: bool.fromEnvironment(
        'TILAWA_LAUNCH_SYSTEM_CHROME',
        defaultValue: true,
      ),
      nonCriticalServices: bool.fromEnvironment(
        'TILAWA_LAUNCH_NON_CRITICAL_SERVICES',
        defaultValue: true,
      ),
      deferredNotificationChannel: bool.fromEnvironment(
        'TILAWA_LAUNCH_DEFERRED_NOTIFICATION_CHANNEL',
        defaultValue: true,
      ),
      crashlyticsInit: bool.fromEnvironment(
        'TILAWA_LAUNCH_CRASHLYTICS_INIT',
        defaultValue: true,
      ),
      hiveInit: bool.fromEnvironment(
        'TILAWA_LAUNCH_HIVE_INIT',
        defaultValue: true,
      ),
      analyticsInit: bool.fromEnvironment(
        'TILAWA_LAUNCH_ANALYTICS_INIT',
        defaultValue: true,
      ),
      notificationServiceInit: bool.fromEnvironment(
        'TILAWA_LAUNCH_NOTIFICATION_SERVICE_INIT',
        defaultValue: true,
      ),
      notificationHandlersInit: bool.fromEnvironment(
        'TILAWA_LAUNCH_NOTIFICATION_HANDLERS_INIT',
        defaultValue: true,
      ),
      athkarNotificationsInit: bool.fromEnvironment(
        'TILAWA_LAUNCH_ATHKAR_NOTIFICATIONS_INIT',
        defaultValue: true,
      ),
      prayerNotificationsInit: bool.fromEnvironment(
        'TILAWA_LAUNCH_PRAYER_NOTIFICATIONS_INIT',
        defaultValue: true,
      ),
      downloadsInit: bool.fromEnvironment(
        'TILAWA_LAUNCH_DOWNLOADS_INIT',
        defaultValue: true,
      ),
      audioServiceInit: bool.fromEnvironment(
        'TILAWA_LAUNCH_AUDIO_SERVICE_INIT',
        defaultValue: true,
      ),
      quranDataLoad: bool.fromEnvironment(
        'TILAWA_LAUNCH_QURAN_DATA_LOAD',
        defaultValue: true,
      ),
      quranAssetsPrefetch: bool.fromEnvironment(
        'TILAWA_LAUNCH_QURAN_ASSETS_PREFETCH',
        defaultValue: true,
      ),
      firebaseDataInit: bool.fromEnvironment(
        'TILAWA_LAUNCH_FIREBASE_DATA_INIT',
        defaultValue: true,
      ),
      subscriptionServiceEnabled: bool.fromEnvironment(
        'TILAWA_LAUNCH_SUBSCRIPTION_SERVICE_ENABLED',
        defaultValue: false,
      ),
      supportTilawaEnabled: bool.fromEnvironment(
        'TILAWA_LAUNCH_SUPPORT_TILAWA_ENABLED',
        defaultValue: true,
      ),
      recitationPracticeEnabled: bool.fromEnvironment(
        'TILAWA_LAUNCH_RECITATION_PRACTICE_ENABLED',
        defaultValue: false,
      ),
      smartKhatmaEnabled: bool.fromEnvironment(
        'TILAWA_LAUNCH_SMART_KHATMA_ENABLED',
        defaultValue: false,
      ),
      todayPlanEnabled: bool.fromEnvironment(
        'TILAWA_LAUNCH_TODAY_PLAN_ENABLED',
        defaultValue: false,
      ),
      notificationPermissionRequest: bool.fromEnvironment(
        'TILAWA_LAUNCH_NOTIFICATION_PERMISSION_REQUEST',
        defaultValue: true,
      ),
      quranSessionsEnabled: bool.fromEnvironment(
        'TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED',
        defaultValue: true,
      ),
      teacherApplicationEnabled: bool.fromEnvironment(
        'TILAWA_LAUNCH_TEACHER_APPLICATION_ENABLED',
        defaultValue: stagingFlagsOn,
      ),
      teacherApplicationDiscoverability: String.fromEnvironment(
        'TILAWA_LAUNCH_TEACHER_APPLICATION_DISCOVERABILITY',
        defaultValue: 'profileAndEmptyState',
      ),
      quranSessionsBookingEnabled: bool.fromEnvironment(
        'TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED',
        defaultValue: stagingFlagsOn,
      ),
      quranSessionsPaidBookingSandboxEnabled: bool.fromEnvironment(
        'TILAWA_LAUNCH_QURAN_SESSIONS_PAID_BOOKING_SANDBOX_ENABLED',
        defaultValue: false,
      ),
      enabledCallProvidersCsv: String.fromEnvironment(
        'TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS',
        defaultValue: stagingFlagsOn
            ? 'external,mock,livekit'
            : 'external,mock',
      ),
      agoraAppId: String.fromEnvironment(
        'TILAWA_LAUNCH_AGORA_APP_ID',
        defaultValue: '',
      ),
      livekitServerUrl: String.fromEnvironment(
        'TILAWA_LAUNCH_LIVEKIT_URL',
        defaultValue: '',
      ),
      genUiAssistantEnabled: bool.fromEnvironment(
        'TILAWA_LAUNCH_GENUI_ASSISTANT_ENABLED',
        defaultValue: false,
      ),
    );
  }

  final bool resetLaunchState;
  final bool frameWatcher;
  final bool perfInstrumentation;
  final bool firebaseInit;
  final bool hydratedStorageInit;
  final bool foregroundMessaging;
  final bool blocObserver;
  final bool notificationLaunchProbe;
  final bool systemChrome;
  final bool nonCriticalServices;
  final bool deferredNotificationChannel;
  final bool crashlyticsInit;
  final bool hiveInit;
  final bool analyticsInit;
  final bool notificationServiceInit;
  final bool notificationHandlersInit;
  final bool athkarNotificationsInit;
  final bool prayerNotificationsInit;
  final bool downloadsInit;
  final bool audioServiceInit;
  final bool quranDataLoad;
  final bool quranAssetsPrefetch;
  final bool firebaseDataInit;
  final bool subscriptionServiceEnabled;
  final bool supportTilawaEnabled;
  final bool recitationPracticeEnabled;
  final bool smartKhatmaEnabled;
  final bool todayPlanEnabled;
  final bool notificationPermissionRequest;
  final bool quranSessionsEnabled;
  final bool teacherApplicationEnabled;

  /// One of: `none`, `profileOnly`, `profileAndEmptyState`.
  final String teacherApplicationDiscoverability;
  final bool quranSessionsBookingEnabled;

  /// Staging-only sandbox PSP checkout (requires CF
  /// `QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED=true`). Default **false**.
  final bool quranSessionsPaidBookingSandboxEnabled;

  /// Comma-separated RTC providers registered client-side (must match Firestore
  /// `enabledCallProviders`). Example: `external,mock,agora`.
  ///
  /// Play production builds default to `external,mock` only and exclude native
  /// Agora/LiveKit via [tool/configure_rtc_deps.dart] before release AAB build.
  final String enabledCallProvidersCsv;

  /// Agora App ID — required when `agora` is in [enabledCallProvidersCsv].
  final String agoraAppId;

  /// LiveKit server URL (`wss://…`) — required when `livekit` is enabled.
  final String livekitServerUrl;

  /// Gates the AI-generated dynamic UI surface (Smart Quran Plan / MeMuslim
  /// Assistant). Defaults to **false** — when off, no GenUI dependencies are
  /// registered and no AI-driven UI is reachable. The whole feature is a
  /// kill-switch away from being inert.
  ///
  /// Example: `--dart-define=TILAWA_LAUNCH_GENUI_ASSISTANT_ENABLED=true`
  final bool genUiAssistantEnabled;

  @override
  List<Object?> get props => [
    resetLaunchState,
    frameWatcher,
    perfInstrumentation,
    firebaseInit,
    hydratedStorageInit,
    foregroundMessaging,
    blocObserver,
    notificationLaunchProbe,
    systemChrome,
    nonCriticalServices,
    deferredNotificationChannel,
    crashlyticsInit,
    hiveInit,
    analyticsInit,
    notificationServiceInit,
    notificationHandlersInit,
    athkarNotificationsInit,
    prayerNotificationsInit,
    downloadsInit,
    audioServiceInit,
    quranDataLoad,
    quranAssetsPrefetch,
    firebaseDataInit,
    subscriptionServiceEnabled,
    supportTilawaEnabled,
    recitationPracticeEnabled,
    smartKhatmaEnabled,
    todayPlanEnabled,
    notificationPermissionRequest,
    quranSessionsEnabled,
    teacherApplicationEnabled,
    teacherApplicationDiscoverability,
    quranSessionsBookingEnabled,
    quranSessionsPaidBookingSandboxEnabled,
    enabledCallProvidersCsv,
    agoraAppId,
    livekitServerUrl,
    genUiAssistantEnabled,
  ];
}
