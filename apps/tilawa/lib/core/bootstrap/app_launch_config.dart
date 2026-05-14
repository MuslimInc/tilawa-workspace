import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Launch-time feature toggles for startup orchestration.
///
/// Most toggles default to enabled and can be overridden via `--dart-define`.
/// [subscriptionServiceEnabled] defaults to **false** so subscription
/// Firestore usage in `SubscriptionPlansService` (catalog, premium status,
/// purchase records) stays off until explicitly enabled.
///
/// Example: `--dart-define=TILAWA_LAUNCH_FIREBASE_INIT=false`
/// Example: `--dart-define=TILAWA_LAUNCH_SUBSCRIPTION_SERVICE_ENABLED=true`
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
    this.credentialManagerInit = true,
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
    this.notificationPermissionRequest = true,
    this.compactUiEnabled = true,
  });

  factory AppLaunchConfig.fromEnvironment() {
    return const AppLaunchConfig(
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
      credentialManagerInit: bool.fromEnvironment(
        'TILAWA_LAUNCH_CREDENTIAL_MANAGER_INIT',
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
      notificationPermissionRequest: bool.fromEnvironment(
        'TILAWA_LAUNCH_NOTIFICATION_PERMISSION_REQUEST',
        defaultValue: true,
      ),
      compactUiEnabled: bool.fromEnvironment(
        'TILAWA_COMPACT_UI',
        defaultValue: true,
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
  final bool credentialManagerInit;
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
  final bool notificationPermissionRequest;

  /// Default for UI density when no persisted [SettingsState.useCompactDesign]
  /// exists (see `SettingsCubit.fromJson`). Overridable via
  /// `--dart-define=TILAWA_COMPACT_UI=false`.
  final bool compactUiEnabled;

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
    credentialManagerInit,
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
    notificationPermissionRequest,
    compactUiEnabled,
  ];
}
