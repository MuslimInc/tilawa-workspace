import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/crash_reporting_context.dart';
import 'package:tilawa/core/telemetry/distribution_config.dart';

void main() {
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
}
