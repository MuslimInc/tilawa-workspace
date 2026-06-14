import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
    if (event.tags?[CrashReportingTagKeys.sentryVerify] == 'true') {
      return event;
    }

    if (!kReleaseMode) {
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
    return (kind: 'unknown', name: 'unknown');
  }

  static Future<String> _resolveInstallSource() async {
    if (kIsWeb) {
      return 'web';
    }
    if (!Platform.isAndroid) {
      return 'unknown';
    }

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
  }

  @visibleForTesting
  static void resetForTesting() {
    _sentryTags = null;
    _crashlyticsKeys = null;
  }
}
