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
}
