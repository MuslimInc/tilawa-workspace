import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa_core/services/wakelock_keep_awake_service.dart';

import 'distribution_config.dart';

/// Tag keys shared by Sentry (indexed tags) and Crashlytics (custom keys).
abstract final class CrashReportingTagKeys {
  /// Physical device vs emulator/simulator. Uses [device.kind] instead of
  /// `device.class` so we do not collide with Sentry's performance tier tag.
  static const String deviceKind = 'device.kind';
  static const String deviceName = 'device.name';
  static const String buildMode = 'build.mode';
  static const String distribution = 'distribution';
  static const String installSource = 'install.source';
  static const String buildNumber = 'build.number';
  static const String sentryVerify = 'sentry.verify';

  static const String deviceKindCrashlytics = 'device_kind';
  static const String deviceNameCrashlytics = 'device_name';
  static const String buildModeCrashlytics = 'build_mode';
  static const String distributionCrashlytics = 'distribution';
  static const String installSourceCrashlytics = 'install_source';
  static const String buildNumberCrashlytics = 'build_number';
}

/// Collects device / build / distribution context for crash reporters.
abstract final class CrashReportingContext {
  static const MethodChannel _androidInstallChannel = MethodChannel(
    'com.tilawa.app/app_context',
  );

  static Map<String, String>? _sentryTags;
  static Map<String, String>? _crashlyticsKeys;

  /// Applies indexed tags to the active Sentry scope.
  static Future<void> applyToSentry() async {
    final Map<String, String> tags = await sentryTags();
    await Sentry.configureScope((Scope scope) {
      for (final MapEntry<String, String> entry in tags.entries) {
        scope.setTag(entry.key, entry.value);
      }
    });
  }

  /// Key/value pairs for Crashlytics custom keys.
  static Future<Map<String, String>> crashlyticsKeys() async {
    return _crashlyticsKeys ??= await _collectCrashlyticsKeys();
  }

  /// Indexed Sentry tags.
  static Future<Map<String, String>> sentryTags() async {
    return _sentryTags ??= await _collectSentryTags();
  }

  /// Drops emulator/simulator events in release builds.
  static SentryEvent? filterEmulatorsInRelease(SentryEvent event, Hint hint) {
    return filterEmulatorsForMode(event: event, releaseMode: kReleaseMode);
  }

  @visibleForTesting
  static SentryEvent? filterEmulatorsForMode({
    required SentryEvent event,
    required bool releaseMode,
  }) {
    if (event.tags?[CrashReportingTagKeys.sentryVerify] == 'true') {
      return event;
    }

    if (!releaseMode) {
      return event;
    }

    final bool? simulator = event.contexts.device?.simulator;
    if (simulator == true) {
      return null;
    }

    final String? deviceKind = event.tags?[CrashReportingTagKeys.deviceKind];
    if (deviceKind == 'emulator' || deviceKind == 'simulator') {
      return null;
    }

    return event;
  }

  /// Chained [beforeSend]: emulator filter, then wakelock lifecycle noise.
  static SentryEvent? filterBeforeSend(SentryEvent event, Hint hint) {
    final SentryEvent? afterEmulator = filterEmulatorsInRelease(event, hint);
    if (afterEmulator == null) {
      return null;
    }
    final SentryEvent? afterWakelock = filterWakelockPlatformNoiseInRelease(
      afterEmulator,
      hint,
    );
    if (afterWakelock == null) {
      return null;
    }
    return filterExpectedSessionNoiseInRelease(afterWakelock, hint);
  }

  /// Drops expected auth invalidation and empty-route [StateError] noise.
  @visibleForTesting
  static SentryEvent? filterExpectedSessionNoiseInRelease(
    SentryEvent event,
    Hint hint,
  ) {
    return filterExpectedSessionNoiseForMode(
      event: event,
      releaseMode: kReleaseMode,
    );
  }

  @visibleForTesting
  static SentryEvent? filterExpectedSessionNoiseForMode({
    required SentryEvent event,
    required bool releaseMode,
  }) {
    if (!releaseMode) {
      return event;
    }

    final Object? throwable = event.throwable;
    if (throwable != null) {
      if (isIgnorableAuthSessionNoise(throwable)) {
        return null;
      }
      if (isIgnorableEmptyRouteStateError(event)) {
        return null;
      }
    }

    final String formattedMessage = _eventMessageText(event);
    if (formattedMessage.isNotEmpty &&
        isIgnorableAuthSessionNoise(formattedMessage)) {
      return null;
    }

    return event;
  }

  /// True for Firebase Auth invalid-credential / forced re-sign-in noise.
  @visibleForTesting
  static bool isIgnorableAuthSessionNoise(Object error) {
    final String description = error.toString().toLowerCase();
    return description.contains('credential is no longer valid') ||
        description.contains('user must sign in again') ||
        description.contains('user-token-expired') ||
        description.contains('session_expired') ||
        description.contains('[firebase_auth/');
  }

  /// True when [StateError] (No element) happens during Android back / route pop.
  @visibleForTesting
  static bool isIgnorableEmptyRouteStateError(SentryEvent event) {
    final Object? throwable = event.throwable;
    if (throwable is! StateError) {
      return false;
    }
    final String message = throwable.message;
    if (!message.contains('No element')) {
      return false;
    }
    return _eventDiagnosticText(event).contains('didPopRoute');
  }

  static String _eventDiagnosticText(SentryEvent event) {
    final StringBuffer buffer = StringBuffer(_eventMessageText(event));
    for (final MapEntry<String, dynamic> entry in event.contexts.entries) {
      buffer
        ..write(entry.key)
        ..write(entry.value);
    }
    return buffer.toString();
  }

  /// Drops wakelock/no-foreground-activity platform errors in release builds.
  @visibleForTesting
  static SentryEvent? filterWakelockPlatformNoiseInRelease(
    SentryEvent event,
    Hint hint,
  ) {
    return filterWakelockPlatformNoiseForMode(
      event: event,
      releaseMode: kReleaseMode,
    );
  }

  @visibleForTesting
  static SentryEvent? filterWakelockPlatformNoiseForMode({
    required SentryEvent event,
    required bool releaseMode,
  }) {
    if (!releaseMode) {
      return event;
    }

    final Object? throwable = event.throwable;
    if (throwable != null && isIgnorableWakelockPlatformNoise(throwable)) {
      return null;
    }

    final String formattedMessage = _eventMessageText(event);
    if (formattedMessage.isNotEmpty &&
        isIgnorableWakelockPlatformNoise(formattedMessage)) {
      return null;
    }

    return event;
  }

  static String _eventMessageText(SentryEvent event) {
    final dynamic message = event.message;
    if (message == null) {
      return '';
    }
    if (message is String) {
      return message;
    }
    try {
      final Object? formatted = (message as dynamic).formatted;
      if (formatted is String) {
        return formatted;
      }
    } on Object {
      // Fall through to toString().
    }
    return message.toString();
  }

  /// Chained [beforeSendLog]: emulator filter, then wakelock lifecycle noise.
  static SentryLog? filterBeforeSendLog(SentryLog log) {
    final SentryLog? afterEmulator = filterEmulatorLogsInRelease(log);
    if (afterEmulator == null) {
      return null;
    }
    final SentryLog? afterWakelock = filterWakelockLogsInRelease(afterEmulator);
    if (afterWakelock == null) {
      return null;
    }
    return filterAuthSessionLogsInRelease(afterWakelock);
  }

  /// Drops auth invalidation structured logs in release builds.
  @visibleForTesting
  static SentryLog? filterAuthSessionLogsInRelease(SentryLog log) {
    return filterAuthSessionLogsForMode(log: log, releaseMode: kReleaseMode);
  }

  @visibleForTesting
  static SentryLog? filterAuthSessionLogsForMode({
    required SentryLog log,
    required bool releaseMode,
  }) {
    if (!releaseMode) {
      return log;
    }

    if (isIgnorableAuthSessionNoise(log.body)) {
      return null;
    }

    return log;
  }

  /// Drops wakelock/no-foreground-activity structured logs in release builds.
  @visibleForTesting
  static SentryLog? filterWakelockLogsInRelease(SentryLog log) {
    return filterWakelockLogsForMode(log: log, releaseMode: kReleaseMode);
  }

  @visibleForTesting
  static SentryLog? filterWakelockLogsForMode({
    required SentryLog log,
    required bool releaseMode,
  }) {
    if (!releaseMode) {
      return log;
    }

    if (isIgnorableWakelockPlatformNoise(log.body)) {
      return null;
    }

    return log;
  }

  /// Drops emulator/simulator structured logs in release builds.
  ///
  /// Uses the cached [device.kind] tag from [applyToSentry] — Sentry logs are
  /// not enriched with `device.simulator` in SDK 9.21.
  static SentryLog? filterEmulatorLogsInRelease(SentryLog log) {
    final String? deviceKind = _sentryTags?[CrashReportingTagKeys.deviceKind];
    return filterEmulatorLogsForMode(
      log: log,
      releaseMode: kReleaseMode,
      deviceKind: deviceKind,
    );
  }

  @visibleForTesting
  static SentryLog? filterEmulatorLogsForMode({
    required SentryLog log,
    required bool releaseMode,
    String? deviceKind,
  }) {
    if (!releaseMode) {
      return log;
    }

    if (deviceKind == 'emulator' || deviceKind == 'simulator') {
      return null;
    }

    return log;
  }

  @visibleForTesting
  static String resolveBuildMode({
    required bool debugMode,
    required bool profileMode,
  }) {
    if (debugMode) {
      return 'debug';
    }
    if (profileMode) {
      return 'profile';
    }
    return 'release';
  }

  @visibleForTesting
  static String mapInstallSource(String? installerPackage) {
    if (installerPackage == null || installerPackage.isEmpty) {
      return 'sideload';
    }
    return switch (installerPackage) {
      'com.android.vending' => 'play_store',
      'com.apple.AppStore' => 'app_store',
      _ => 'other_store',
    };
  }

  @visibleForTesting
  static String resolveDeviceKind({
    required bool isPhysicalDevice,
    required bool isIOS,
  }) {
    if (isPhysicalDevice) {
      return 'physical';
    }
    return isIOS ? 'simulator' : 'emulator';
  }

  /// Resolves Android [CrashReportingTagKeys.deviceKind], including AOSP
  /// images that incorrectly report [isPhysicalDevice] as true.
  @visibleForTesting
  static String resolveAndroidDeviceKind({
    required bool isPhysicalDevice,
    String? fingerprint,
    String? product,
    String? model,
    String? hardware,
    String? brand,
  }) {
    if (!isPhysicalDevice ||
        looksLikeAndroidEmulatorBuild(
          fingerprint: fingerprint,
          product: product,
          model: model,
          hardware: hardware,
          brand: brand,
        )) {
      return 'emulator';
    }
    return 'physical';
  }

  @visibleForTesting
  static bool looksLikeAndroidEmulatorBuild({
    String? fingerprint,
    String? product,
    String? model,
    String? hardware,
    String? brand,
  }) {
    final Iterable<String> haystacks = <String?>[
      fingerprint,
      product,
      model,
      hardware,
      brand,
    ].whereType<String>().map((String value) => value.toLowerCase());

    for (final String haystack in haystacks) {
      if (haystack.contains('generic') ||
          haystack.contains('emulator') ||
          haystack.contains('sdk_gphone') ||
          haystack.contains('sdk_phone') ||
          haystack.contains('goldfish') ||
          haystack.contains('ranchu') ||
          haystack.contains('google_sdk') ||
          haystack.contains('android sdk built for')) {
        return true;
      }
    }

    final String? normalizedFingerprint = fingerprint?.toLowerCase();
    if (normalizedFingerprint != null &&
        normalizedFingerprint.contains('test-keys')) {
      return true;
    }

    return false;
  }

  static Future<Map<String, String>> _collectSentryTags() async {
    final ({String kind, String name}) device = await _resolveDeviceInfo();
    final String buildMode = resolveBuildMode(
      debugMode: kDebugMode,
      profileMode: kProfileMode,
    );
    final String installSource = await _resolveInstallSource();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    return <String, String>{
      CrashReportingTagKeys.deviceKind: device.kind,
      CrashReportingTagKeys.deviceName: device.name,
      CrashReportingTagKeys.buildMode: buildMode,
      CrashReportingTagKeys.distribution: DistributionConfig.distribution,
      CrashReportingTagKeys.installSource: installSource,
      CrashReportingTagKeys.buildNumber: packageInfo.buildNumber,
    };
  }

  static Future<Map<String, String>> _collectCrashlyticsKeys() async {
    final Map<String, String> sentry = await sentryTags();
    return <String, String>{
      CrashReportingTagKeys.deviceKindCrashlytics:
          sentry[CrashReportingTagKeys.deviceKind]!,
      CrashReportingTagKeys.deviceNameCrashlytics:
          sentry[CrashReportingTagKeys.deviceName]!,
      CrashReportingTagKeys.buildModeCrashlytics:
          sentry[CrashReportingTagKeys.buildMode]!,
      CrashReportingTagKeys.distributionCrashlytics:
          sentry[CrashReportingTagKeys.distribution]!,
      CrashReportingTagKeys.installSourceCrashlytics:
          sentry[CrashReportingTagKeys.installSource]!,
      CrashReportingTagKeys.buildNumberCrashlytics:
          sentry[CrashReportingTagKeys.buildNumber]!,
    };
  }

  static Future<({String kind, String name})> _resolveDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    // coverage:ignore-start
    if (Platform.isAndroid) {
      final AndroidDeviceInfo info = await deviceInfo.androidInfo;
      final String name = info.model.trim().isNotEmpty
          ? info.model
          : info.device;
      return (
        kind: resolveAndroidDeviceKind(
          isPhysicalDevice: info.isPhysicalDevice,
          fingerprint: info.fingerprint,
          product: info.product,
          model: info.model,
          hardware: info.hardware,
          brand: info.brand,
        ),
        name: name,
      );
    }
    if (Platform.isIOS) {
      final IosDeviceInfo info = await deviceInfo.iosInfo;
      final String name = info.model.trim().isNotEmpty
          ? info.model
          : info.utsname.machine;
      return (
        kind: resolveDeviceKind(
          isPhysicalDevice: info.isPhysicalDevice,
          isIOS: true,
        ),
        name: name,
      );
    }
    // coverage:ignore-end
    return (kind: 'unknown', name: 'unknown');
  }

  static Future<String> _resolveInstallSource() async {
    if (kIsWeb) {
      return 'web';
    }
    if (!Platform.isAndroid) {
      return 'unknown';
    }

    // coverage:ignore-start
    try {
      final String? installer = await _androidInstallChannel
          .invokeMethod<String>(
            'getInstallerPackageName',
          );
      return mapInstallSource(installer);
    } on PlatformException {
      return 'unknown';
    } on MissingPluginException {
      return 'unknown';
    }
    // coverage:ignore-end
  }

  @visibleForTesting
  static void resetForTesting() {
    _sentryTags = null;
    _crashlyticsKeys = null;
  }

  @visibleForTesting
  static void setSentryTagsCacheForTesting(Map<String, String>? tags) {
    _sentryTags = tags;
  }
}
