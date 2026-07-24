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
/// [reportBugEnabled] defaults to **false** (Settings "Report a bug" + Sentry
/// feedback prompts) until explicitly enabled.
///
/// Example: `--dart-define=TILAWA_LAUNCH_FIREBASE_INIT=false`
/// Example: `--dart-define=TILAWA_LAUNCH_SUBSCRIPTION_SERVICE_ENABLED=true`
/// Example: `--dart-define=TILAWA_LAUNCH_SUPPORT_TILAWA_ENABLED=false`
/// Example: `--dart-define=TILAWA_LAUNCH_REPORT_BUG_ENABLED=true`
/// Example: `--dart-define=TILAWA_LAUNCH_RECITATION_PRACTICE_ENABLED=true`
/// Example: `--dart-define=TILAWA_LAUNCH_SMART_KHATMA_ENABLED=true`
/// Example: `--dart-define=TILAWA_LAUNCH_WIRD_WIDGET_ENABLED=true`
/// Example: `--dart-define=TILAWA_LAUNCH_TODAY_PLAN_ENABLED=true`
/// Example: `--dart-define=TILAWA_LAUNCH_TEACHER_APPLICATION_FORM_URL=https://…`
/// Example: `--dart-define=TILAWA_LAUNCH_AGORA_APP_ID=your_agora_app_id`
/// Example: `--dart-define=TILAWA_LAUNCH_LIVEKIT_URL=wss://tilawa-7whzug8z.livekit.cloud`
/// Example: `--dart-define=TILAWA_LAUNCH_DEVICE_REGISTRY_WRITE_ENABLED=true`
/// Example: `--dart-define=TILAWA_LAUNCH_MULTI_DEVICE_LOGIN_ENABLED=false`
///
/// Quran Sessions product behavior is controlled by Admin Panel Firestore
/// config, not launch config. Launch config only carries SDK credentials such
/// as Agora App ID and LiveKit URL.
/// Google Form for experienced Quran teacher/tutor applications (production default).
const String kDefaultTeacherApplicationFormUrl =
    'https://docs.google.com/forms/d/e/1FAIpQLScjFOySgVJqDxaY0IgR9GYDEnemxOkPSbW2QQea7KrORvRQQA/viewform';

/// Compile-time `--dart-define` values for [AppLaunchConfig.fromEnvironment].
///
/// [bool.fromEnvironment] only reads defines in a **constant** context; calling
/// it inside a non-const factory body always returns [defaultValue].
abstract final class _LaunchEnvironment {
  const _LaunchEnvironment._();

  static const String distribution = String.fromEnvironment(
    'TILAWA_DISTRIBUTION',
    defaultValue: 'local',
  );
  static const bool stagingFlagsOn = distribution != 'play_production';

  static const bool resetLaunchState = bool.fromEnvironment(
    'TILAWA_LAUNCH_RESET_LAUNCH_STATE',
    defaultValue: true,
  );
  static const bool frameWatcher = bool.fromEnvironment(
    'TILAWA_LAUNCH_FRAME_WATCHER',
    defaultValue: true,
  );
  static const bool perfInstrumentation = bool.fromEnvironment(
    'TILAWA_LAUNCH_PERF_INSTRUMENTATION',
    defaultValue: kProfileMode,
  );
  static const bool firebaseInit = bool.fromEnvironment(
    'TILAWA_LAUNCH_FIREBASE_INIT',
    defaultValue: true,
  );
  static const bool hydratedStorageInit = bool.fromEnvironment(
    'TILAWA_LAUNCH_HYDRATED_STORAGE_INIT',
    defaultValue: true,
  );
  static const bool foregroundMessaging = bool.fromEnvironment(
    'TILAWA_LAUNCH_FOREGROUND_MESSAGING',
    defaultValue: true,
  );
  static const bool blocObserver = bool.fromEnvironment(
    'TILAWA_LAUNCH_BLOC_OBSERVER',
    defaultValue: kDebugMode,
  );
  static const bool notificationLaunchProbe = bool.fromEnvironment(
    'TILAWA_LAUNCH_NOTIFICATION_LAUNCH_PROBE',
    defaultValue: true,
  );
  static const bool systemChrome = bool.fromEnvironment(
    'TILAWA_LAUNCH_SYSTEM_CHROME',
    defaultValue: true,
  );
  static const bool nonCriticalServices = bool.fromEnvironment(
    'TILAWA_LAUNCH_NON_CRITICAL_SERVICES',
    defaultValue: true,
  );
  static const bool deferredNotificationChannel = bool.fromEnvironment(
    'TILAWA_LAUNCH_DEFERRED_NOTIFICATION_CHANNEL',
    defaultValue: true,
  );
  static const bool crashlyticsInit = bool.fromEnvironment(
    'TILAWA_LAUNCH_CRASHLYTICS_INIT',
    defaultValue: true,
  );
  static const bool hiveInit = bool.fromEnvironment(
    'TILAWA_LAUNCH_HIVE_INIT',
    defaultValue: true,
  );
  static const bool analyticsInit = bool.fromEnvironment(
    'TILAWA_LAUNCH_ANALYTICS_INIT',
    defaultValue: true,
  );
  static const bool notificationServiceInit = bool.fromEnvironment(
    'TILAWA_LAUNCH_NOTIFICATION_SERVICE_INIT',
    defaultValue: true,
  );
  static const bool notificationHandlersInit = bool.fromEnvironment(
    'TILAWA_LAUNCH_NOTIFICATION_HANDLERS_INIT',
    defaultValue: true,
  );
  static const bool athkarNotificationsInit = bool.fromEnvironment(
    'TILAWA_LAUNCH_ATHKAR_NOTIFICATIONS_INIT',
    defaultValue: true,
  );
  static const bool prayerNotificationsInit = bool.fromEnvironment(
    'TILAWA_LAUNCH_PRAYER_NOTIFICATIONS_INIT',
    defaultValue: true,
  );
  static const bool downloadsInit = bool.fromEnvironment(
    'TILAWA_LAUNCH_DOWNLOADS_INIT',
    defaultValue: true,
  );
  static const bool audioServiceInit = bool.fromEnvironment(
    'TILAWA_LAUNCH_AUDIO_SERVICE_INIT',
    defaultValue: true,
  );
  static const bool quranDataLoad = bool.fromEnvironment(
    'TILAWA_LAUNCH_QURAN_DATA_LOAD',
    defaultValue: true,
  );
  static const bool quranAssetsPrefetch = bool.fromEnvironment(
    'TILAWA_LAUNCH_QURAN_ASSETS_PREFETCH',
    defaultValue: true,
  );
  static const bool firebaseDataInit = bool.fromEnvironment(
    'TILAWA_LAUNCH_FIREBASE_DATA_INIT',
    defaultValue: true,
  );
  static const bool subscriptionServiceEnabled = bool.fromEnvironment(
    'TILAWA_LAUNCH_SUBSCRIPTION_SERVICE_ENABLED',
    defaultValue: false,
  );
  static const bool supportTilawaEnabled = bool.fromEnvironment(
    'TILAWA_LAUNCH_SUPPORT_TILAWA_ENABLED',
    defaultValue: true,
  );
  static const bool reportBugEnabled = bool.fromEnvironment(
    'TILAWA_LAUNCH_REPORT_BUG_ENABLED',
    defaultValue: false,
  );
  static const bool recitationPracticeEnabled = bool.fromEnvironment(
    'TILAWA_LAUNCH_RECITATION_PRACTICE_ENABLED',
    defaultValue: false,
  );
  static const bool smartKhatmaEnabled = bool.fromEnvironment(
    'TILAWA_LAUNCH_SMART_KHATMA_ENABLED',
    defaultValue: true,
  );
  static const bool wirdWidgetEnabled = bool.fromEnvironment(
    'TILAWA_LAUNCH_WIRD_WIDGET_ENABLED',
    defaultValue: false,
  );
  static const bool todayPlanEnabled = bool.fromEnvironment(
    'TILAWA_LAUNCH_TODAY_PLAN_ENABLED',
    defaultValue: false,
  );
  static const bool notificationPermissionRequest = bool.fromEnvironment(
    'TILAWA_LAUNCH_NOTIFICATION_PERMISSION_REQUEST',
    defaultValue: true,
  );
  static const bool teacherDashboardSummaryReadEnabled = bool.fromEnvironment(
    'TILAWA_LAUNCH_TEACHER_DASHBOARD_SUMMARY_READ_ENABLED',
    defaultValue: stagingFlagsOn,
  );
  static const bool deviceRegistryWriteEnabled = bool.fromEnvironment(
    'TILAWA_LAUNCH_DEVICE_REGISTRY_WRITE_ENABLED',
    defaultValue: stagingFlagsOn,
  );
  static const bool multiDeviceLoginEnabled = bool.fromEnvironment(
    'TILAWA_LAUNCH_MULTI_DEVICE_LOGIN_ENABLED',
    defaultValue: true,
  );
  static const bool authLifecycleHardeningEnabled = bool.fromEnvironment(
    'TILAWA_LAUNCH_AUTH_LIFECYCLE_HARDENING_ENABLED',
    defaultValue: stagingFlagsOn,
  );
  static const String teacherApplicationFormUrl = String.fromEnvironment(
    'TILAWA_LAUNCH_TEACHER_APPLICATION_FORM_URL',
    defaultValue: kDefaultTeacherApplicationFormUrl,
  );
  static const String agoraAppId = String.fromEnvironment(
    'TILAWA_LAUNCH_AGORA_APP_ID',
    defaultValue: '',
  );
  static const String livekitServerUrl = String.fromEnvironment(
    'TILAWA_LAUNCH_LIVEKIT_URL',
    defaultValue: '',
  );
  static const bool genUiAssistantEnabled = bool.fromEnvironment(
    'TILAWA_LAUNCH_GENUI_ASSISTANT_ENABLED',
    defaultValue: false,
  );
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
    this.reportBugEnabled = false,
    this.recitationPracticeEnabled = false,
    this.smartKhatmaEnabled = false,
    this.wirdWidgetEnabled = false,
    this.todayPlanEnabled = false,
    this.notificationPermissionRequest = true,
    this.teacherDashboardSummaryReadEnabled = false,
    this.deviceRegistryWriteEnabled = false,
    this.multiDeviceLoginEnabled = true,
    this.authLifecycleHardeningEnabled = false,
    this.teacherApplicationFormUrl = kDefaultTeacherApplicationFormUrl,
    this.agoraAppId = '',
    this.livekitServerUrl = '',
    this.genUiAssistantEnabled = false,
  });

  factory AppLaunchConfig.fromEnvironment() {
    return const AppLaunchConfig(
      resetLaunchState: _LaunchEnvironment.resetLaunchState,
      frameWatcher: _LaunchEnvironment.frameWatcher,
      perfInstrumentation: _LaunchEnvironment.perfInstrumentation,
      firebaseInit: _LaunchEnvironment.firebaseInit,
      hydratedStorageInit: _LaunchEnvironment.hydratedStorageInit,
      foregroundMessaging: _LaunchEnvironment.foregroundMessaging,
      blocObserver: _LaunchEnvironment.blocObserver,
      notificationLaunchProbe: _LaunchEnvironment.notificationLaunchProbe,
      systemChrome: _LaunchEnvironment.systemChrome,
      nonCriticalServices: _LaunchEnvironment.nonCriticalServices,
      deferredNotificationChannel:
          _LaunchEnvironment.deferredNotificationChannel,
      crashlyticsInit: _LaunchEnvironment.crashlyticsInit,
      hiveInit: _LaunchEnvironment.hiveInit,
      analyticsInit: _LaunchEnvironment.analyticsInit,
      notificationServiceInit: _LaunchEnvironment.notificationServiceInit,
      notificationHandlersInit: _LaunchEnvironment.notificationHandlersInit,
      athkarNotificationsInit: _LaunchEnvironment.athkarNotificationsInit,
      prayerNotificationsInit: _LaunchEnvironment.prayerNotificationsInit,
      downloadsInit: _LaunchEnvironment.downloadsInit,
      audioServiceInit: _LaunchEnvironment.audioServiceInit,
      quranDataLoad: _LaunchEnvironment.quranDataLoad,
      quranAssetsPrefetch: _LaunchEnvironment.quranAssetsPrefetch,
      firebaseDataInit: _LaunchEnvironment.firebaseDataInit,
      subscriptionServiceEnabled: _LaunchEnvironment.subscriptionServiceEnabled,
      supportTilawaEnabled: _LaunchEnvironment.supportTilawaEnabled,
      reportBugEnabled: _LaunchEnvironment.reportBugEnabled,
      recitationPracticeEnabled: _LaunchEnvironment.recitationPracticeEnabled,
      smartKhatmaEnabled: _LaunchEnvironment.smartKhatmaEnabled,
      wirdWidgetEnabled: _LaunchEnvironment.wirdWidgetEnabled,
      todayPlanEnabled: _LaunchEnvironment.todayPlanEnabled,
      notificationPermissionRequest:
          _LaunchEnvironment.notificationPermissionRequest,
      teacherDashboardSummaryReadEnabled:
          _LaunchEnvironment.teacherDashboardSummaryReadEnabled,
      deviceRegistryWriteEnabled: _LaunchEnvironment.deviceRegistryWriteEnabled,
      multiDeviceLoginEnabled: _LaunchEnvironment.multiDeviceLoginEnabled,
      authLifecycleHardeningEnabled:
          _LaunchEnvironment.authLifecycleHardeningEnabled,
      teacherApplicationFormUrl: _LaunchEnvironment.teacherApplicationFormUrl,
      agoraAppId: _LaunchEnvironment.agoraAppId,
      livekitServerUrl: _LaunchEnvironment.livekitServerUrl,
      genUiAssistantEnabled: _LaunchEnvironment.genUiAssistantEnabled,
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

  /// Settings "Report a bug" tile and Sentry user-feedback prompts.
  /// Defaults to **false**. Enable with:
  /// `--dart-define=TILAWA_LAUNCH_REPORT_BUG_ENABLED=true`
  final bool reportBugEnabled;
  final bool recitationPracticeEnabled;
  final bool smartKhatmaEnabled;
  final bool wirdWidgetEnabled;
  final bool todayPlanEnabled;
  final bool notificationPermissionRequest;

  /// One-read teacher dashboard: serve `/sessions/dashboard` from the
  /// server-maintained summary doc, falling back to per-collection reads.
  /// Default off in production, on for staging/local builds.
  final bool teacherDashboardSummaryReadEnabled;

  /// Phase 0 of the multi-device strategy (ADR-008): when on, sign-in/device
  /// registration also upserts the non-exclusive `users/{uid}/devices/{deviceId}`
  /// registry alongside the existing single-device behavior. Purely additive and
  /// reversible — no login/`sessionEpoch` behavior changes until Phase 1.
  /// Default off in production, on for staging/local builds.
  final bool deviceRegistryWriteEnabled;

  /// Phase 1 of the multi-device strategy (ADR-008): when on, the client no
  /// longer treats a superseded session (`session_revoked` push /
  /// `session_epoch_stale`) as a whole-app logout, enabling true multi-device
  /// login. The matching server gate is the `MULTI_DEVICE_LOGIN_ENABLED`
  /// Functions env var. Default off in production, on for staging/local builds.
  final bool multiDeviceLoginEnabled;

  /// Gates the auth/App Check lifecycle hardening: a transient verification
  /// failure (App Check attestation, token-refresh network/internal errors)
  /// surfaces a non-blocking "verifying your session" state instead of a
  /// destructive logout/redirect. Only a definitive invalidation
  /// (revoked/expired token, disabled/deleted account) ends the session.
  /// Default off in production, on for staging/local builds.
  final bool authLifecycleHardeningEnabled;

  /// External Google Form URL opened from teacher application entry points.
  final String teacherApplicationFormUrl;

  /// Agora App ID — used only when Admin config enables `agora`.
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
    reportBugEnabled,
    recitationPracticeEnabled,
    smartKhatmaEnabled,
    wirdWidgetEnabled,
    todayPlanEnabled,
    notificationPermissionRequest,
    teacherDashboardSummaryReadEnabled,
    deviceRegistryWriteEnabled,
    multiDeviceLoginEnabled,
    authLifecycleHardeningEnabled,
    teacherApplicationFormUrl,
    agoraAppId,
    livekitServerUrl,
    genUiAssistantEnabled,
  ];
}
