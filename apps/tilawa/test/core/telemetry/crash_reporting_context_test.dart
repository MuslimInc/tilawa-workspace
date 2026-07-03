import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/crash_reporting_context.dart';
import 'package:tilawa/core/telemetry/distribution_config.dart';

import 'sentry_test_support.dart';

void main() {
  setUpAll(mockSentryPlatformChannels);
  tearDown(CrashReportingContext.resetForTesting);

  group('resolveBuildMode', () {
    test('returns debug when debugMode is true', () {
      expect(
        CrashReportingContext.resolveBuildMode(
          debugMode: true,
          profileMode: false,
        ),
        'debug',
      );
    });

    test('returns profile when profileMode is true', () {
      expect(
        CrashReportingContext.resolveBuildMode(
          debugMode: false,
          profileMode: true,
        ),
        'profile',
      );
    });

    test('returns release otherwise', () {
      expect(
        CrashReportingContext.resolveBuildMode(
          debugMode: false,
          profileMode: false,
        ),
        'release',
      );
    });
  });

  group('mapInstallSource', () {
    test('maps Play Store installer', () {
      expect(
        CrashReportingContext.mapInstallSource('com.android.vending'),
        'play_store',
      );
    });

    test('maps empty installer to sideload', () {
      expect(CrashReportingContext.mapInstallSource(null), 'sideload');
      expect(CrashReportingContext.mapInstallSource(''), 'sideload');
    });

    test('maps unknown installers to other_store', () {
      expect(
        CrashReportingContext.mapInstallSource('com.example.store'),
        'other_store',
      );
    });
  });

  test('distribution defaults to local', () {
    expect(DistributionConfig.distribution, 'local');
  });

  group('resolveDeviceKind', () {
    test('returns physical for real devices', () {
      expect(
        CrashReportingContext.resolveDeviceKind(
          isPhysicalDevice: true,
          isIOS: false,
        ),
        'physical',
      );
    });

    test('returns emulator for Android virtual devices', () {
      expect(
        CrashReportingContext.resolveDeviceKind(
          isPhysicalDevice: false,
          isIOS: false,
        ),
        'emulator',
      );
    });

    test('returns simulator for iOS simulators', () {
      expect(
        CrashReportingContext.resolveDeviceKind(
          isPhysicalDevice: false,
          isIOS: true,
        ),
        'simulator',
      );
    });
  });

  group('resolveAndroidDeviceKind', () {
    test('returns emulator for sdk_phone fingerprints', () {
      expect(
        CrashReportingContext.resolveAndroidDeviceKind(
          isPhysicalDevice: true,
          fingerprint:
              'Android/sdk_phone_arm64/generic_arm64:14/...:userdebug/test-keys',
          product: 'sdk_phone_arm64',
          model: 'sdk_phone_arm64',
          hardware: 'ranchu',
          brand: 'google',
        ),
        'emulator',
      );
    });

    test('returns physical for retail device fingerprints', () {
      expect(
        CrashReportingContext.resolveAndroidDeviceKind(
          isPhysicalDevice: true,
          fingerprint:
              'samsung/beyond1ltexx/beyond1:13/TP1A.220624.014/release-keys',
          product: 'beyond1ltexx',
          model: 'SM-G973F',
          hardware: 'exynos9820',
          brand: 'samsung',
        ),
        'physical',
      );
    });
  });

  group('looksLikeAndroidEmulatorBuild', () {
    test('detects generic and test-keys fingerprints', () {
      expect(
        CrashReportingContext.looksLikeAndroidEmulatorBuild(
          fingerprint: 'generic/sdk/generic:14/test-keys',
        ),
        isTrue,
      );
    });

    test('returns false for release-key retail builds', () {
      expect(
        CrashReportingContext.looksLikeAndroidEmulatorBuild(
          fingerprint: 'google/redfin/redfin:14/release-keys',
          product: 'redfin',
          model: 'Pixel 5',
          hardware: 'redfin',
          brand: 'google',
        ),
        isFalse,
      );
    });
  });

  group('filterEmulatorsInRelease', () {
    test('keeps verify events tagged sentry.verify', () {
      final SentryEvent event = SentryEvent(
        tags: <String, String>{
          CrashReportingTagKeys.sentryVerify: 'true',
          CrashReportingTagKeys.deviceKind: 'emulator',
        },
      );

      expect(
        CrashReportingContext.filterEmulatorsInRelease(event, Hint()),
        event,
      );
    });
  });

  group('filterWakelockPlatformNoiseForMode', () {
    test('drops wakelock PlatformException in release', () {
      final SentryEvent event = SentryEvent(
        throwable: PlatformException(
          code: 'd',
          message: 'R2.d: wakelock requires a foreground activity',
        ),
      );

      expect(
        CrashReportingContext.filterWakelockPlatformNoiseForMode(
          event: event,
          releaseMode: true,
        ),
        isNull,
      );
    });

    test('keeps unrelated errors in release', () {
      final SentryEvent event = SentryEvent(
        throwable: PlatformException(code: 'OTHER', message: 'network'),
      );

      expect(
        CrashReportingContext.filterWakelockPlatformNoiseForMode(
          event: event,
          releaseMode: true,
        ),
        event,
      );
    });

    test('keeps wakelock noise in debug builds', () {
      final SentryEvent event = SentryEvent(
        throwable: PlatformException(
          code: 'd',
          message: 'wakelock requires a foreground activity',
        ),
      );

      expect(
        CrashReportingContext.filterWakelockPlatformNoiseForMode(
          event: event,
          releaseMode: false,
        ),
        event,
      );
    });

    test('drops wakelock message text in release', () {
      final SentryEvent event = SentryEvent(
        message: SentryMessage('wakelock requires a foreground activity'),
      );

      expect(
        CrashReportingContext.filterWakelockPlatformNoiseForMode(
          event: event,
          releaseMode: true,
        ),
        isNull,
      );
    });
  });

  group('filterWakelockLogsForMode', () {
    final SentryLog wakelockLog = SentryLog(
      timestamp: DateTime.utc(2026),
      level: SentryLogLevel.error,
      body:
          'Uncaught platform error: PlatformException(d, '
          'wakelock requires a foreground activity, null)',
      attributes: <String, SentryAttribute>{},
    );

    test('drops wakelock AppErrorGuard logs in release', () {
      expect(
        CrashReportingContext.filterWakelockLogsForMode(
          log: wakelockLog,
          releaseMode: true,
        ),
        isNull,
      );
    });

    test('keeps wakelock logs in debug', () {
      expect(
        CrashReportingContext.filterWakelockLogsForMode(
          log: wakelockLog,
          releaseMode: false,
        ),
        wakelockLog,
      );
    });
  });

  group('filterBeforeSendLog', () {
    test('drops wakelock logs in release via chained filter', () {
      final SentryLog log = SentryLog(
        timestamp: DateTime.utc(2026),
        level: SentryLogLevel.error,
        body:
            'Uncaught platform error: wakelock requires a foreground activity',
        attributes: <String, SentryAttribute>{},
      );

      expect(
        CrashReportingContext.filterWakelockLogsForMode(
          log: log,
          releaseMode: true,
        ),
        isNull,
      );
    });
  });

  group('filterExpectedSessionNoiseForMode', () {
    test('drops invalid Firebase credential errors in release', () {
      final SentryEvent event = SentryEvent(
        throwable: StateError(
          '[firebase_auth/unknown] credential is no longer valid',
        ),
      );

      expect(
        CrashReportingContext.filterExpectedSessionNoiseForMode(
          event: event,
          releaseMode: true,
        ),
        isNull,
      );
    });

    test('drops No element StateError during didPopRoute in release', () {
      final SentryEvent event = SentryEvent(
        throwable: StateError('Bad state: No element'),
        message: SentryMessage('WidgetsBindingObserver.didPopRoute'),
      );

      expect(
        CrashReportingContext.filterExpectedSessionNoiseForMode(
          event: event,
          releaseMode: true,
        ),
        isNull,
      );
    });

    test('keeps unrelated StateError in release', () {
      final SentryEvent event = SentryEvent(
        throwable: StateError('Bad state: unexpected'),
      );

      expect(
        CrashReportingContext.filterExpectedSessionNoiseForMode(
          event: event,
          releaseMode: true,
        ),
        event,
      );
    });
  });

  group('filterExpectedSessionNoiseForMode auth messages', () {
    test('drops auth invalidation from event message text', () {
      final SentryEvent event = SentryEvent(
        message: SentryMessage('credential is no longer valid'),
      );

      expect(
        CrashReportingContext.filterExpectedSessionNoiseForMode(
          event: event,
          releaseMode: true,
        ),
        isNull,
      );
    });
  });

  group('filterBeforeSendLog auth chain', () {
    test('drops auth invalidation logs in release', () {
      final SentryLog log = SentryLog(
        timestamp: DateTime.utc(2026),
        level: SentryLogLevel.error,
        body: 'user must sign in again',
        attributes: <String, SentryAttribute>{},
      );

      if (kReleaseMode) {
        expect(CrashReportingContext.filterBeforeSendLog(log), isNull);
      } else {
        expect(CrashReportingContext.filterBeforeSendLog(log), log);
      }
    });
  });

  group('filterAuthSessionLogsForMode', () {
    test('drops auth invalidation logs in release', () {
      final SentryLog log = SentryLog(
        timestamp: DateTime.utc(2026),
        level: SentryLogLevel.error,
        body: "The user's credential is no longer valid",
        attributes: <String, SentryAttribute>{},
      );

      expect(
        CrashReportingContext.filterAuthSessionLogsForMode(
          log: log,
          releaseMode: true,
        ),
        isNull,
      );
    });
  });

  group('filterEmulatorsForMode', () {
    test('drops emulator-tagged events in release', () {
      final SentryEvent event = SentryEvent(
        tags: <String, String>{
          CrashReportingTagKeys.deviceKind: 'emulator',
        },
      );

      expect(
        CrashReportingContext.filterEmulatorsForMode(
          event: event,
          releaseMode: true,
        ),
        isNull,
      );
    });

    test('drops simulator context events in release', () {
      final SentryEvent event = SentryEvent(
        contexts: Contexts(device: SentryDevice(simulator: true)),
      );

      expect(
        CrashReportingContext.filterEmulatorsForMode(
          event: event,
          releaseMode: true,
        ),
        isNull,
      );
    });

    test('keeps verify events even on emulators in release', () {
      final SentryEvent event = SentryEvent(
        tags: <String, String>{
          CrashReportingTagKeys.sentryVerify: 'true',
          CrashReportingTagKeys.deviceKind: 'emulator',
        },
      );

      expect(
        CrashReportingContext.filterEmulatorsForMode(
          event: event,
          releaseMode: true,
        ),
        event,
      );
    });
  });

  group('filterBeforeSend', () {
    test('passes benign events through in debug builds', () {
      final SentryEvent event = SentryEvent(message: SentryMessage('ok'));

      expect(
        CrashReportingContext.filterBeforeSend(event, Hint()),
        event,
      );
    });
  });

  group('filterBeforeSendLog', () {
    test('passes benign logs through in debug builds', () {
      final SentryLog log = SentryLog(
        timestamp: DateTime.utc(2026),
        level: SentryLogLevel.info,
        body: 'hello',
        attributes: <String, SentryAttribute>{},
      );

      expect(CrashReportingContext.filterBeforeSendLog(log), log);
    });

    test('drops emulator logs in release when cache says emulator', () {
      CrashReportingContext.setSentryTagsCacheForTesting(<String, String>{
        CrashReportingTagKeys.deviceKind: 'simulator',
      });

      final SentryLog log = SentryLog(
        timestamp: DateTime.utc(2026),
        level: SentryLogLevel.warn,
        body: 'hello',
        attributes: <String, SentryAttribute>{},
      );

      if (kReleaseMode) {
        expect(CrashReportingContext.filterBeforeSendLog(log), isNull);
      } else {
        expect(CrashReportingContext.filterBeforeSendLog(log), log);
      }
    });
  });

  group('isIgnorableAuthSessionNoise', () {
    test('matches firebase auth invalidation patterns', () {
      expect(
        CrashReportingContext.isIgnorableAuthSessionNoise(
          StateError('[firebase_auth/user-token-expired] stale'),
        ),
        isTrue,
      );
      expect(
        CrashReportingContext.isIgnorableAuthSessionNoise(
          Exception('user must sign in again'),
        ),
        isTrue,
      );
      expect(
        CrashReportingContext.isIgnorableAuthSessionNoise(
          Exception('unrelated'),
        ),
        isFalse,
      );
    });
  });

  group('isIgnorableEmptyRouteStateError', () {
    test('matches didPopRoute No element failures', () {
      final SentryEvent event = SentryEvent(
        throwable: StateError('Bad state: No element'),
        message: SentryMessage('WidgetsBindingObserver.didPopRoute'),
      );

      expect(
        CrashReportingContext.isIgnorableEmptyRouteStateError(event),
        isTrue,
      );
    });

    test('ignores unrelated StateError messages', () {
      final SentryEvent event = SentryEvent(
        throwable: StateError('Bad state: other'),
        message: SentryMessage('WidgetsBindingObserver.didPopRoute'),
      );

      expect(
        CrashReportingContext.isIgnorableEmptyRouteStateError(event),
        isFalse,
      );
    });
  });

  group('mapInstallSource', () {
    test('maps App Store installer', () {
      expect(
        CrashReportingContext.mapInstallSource('com.apple.AppStore'),
        'app_store',
      );
    });
  });

  group('tag collection', () {
    test('sentryTags returns stable device and build metadata', () async {
      final Map<String, String> tags = await CrashReportingContext.sentryTags();

      expect(tags, contains(CrashReportingTagKeys.deviceKind));
      expect(tags, contains(CrashReportingTagKeys.buildMode));
      expect(tags, contains(CrashReportingTagKeys.buildNumber));
    });

    test('crashlyticsKeys mirrors sentry tag values', () async {
      final Map<String, String> sentry =
          await CrashReportingContext.sentryTags();
      final Map<String, String> crashlytics =
          await CrashReportingContext.crashlyticsKeys();

      expect(
        crashlytics[CrashReportingTagKeys.deviceKindCrashlytics],
        sentry[CrashReportingTagKeys.deviceKind],
      );
    });

    test('applyToSentry configures scope tags', () async {
      await ensureSentryInitializedForTests();
      await CrashReportingContext.applyToSentry();
    });
  });
}
