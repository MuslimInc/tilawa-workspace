import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/services/crashlytics_service.dart';

class _FakeFirebaseCrashlytics extends Fake implements FirebaseCrashlytics {}

void main() {
  group('FirebaseCrashlyticsServiceImpl', () {
    late FirebaseCrashlyticsServiceImpl service;

    setUp(() {
      service = FirebaseCrashlyticsServiceImpl(_FakeFirebaseCrashlytics());
    });

    group('shouldReportPlatformErrorFatally', () {
      test('returns false for wakelock no-foreground-activity noise', () {
        expect(
          service.shouldReportPlatformErrorFatally(
            PlatformException(
              code: 'd',
              message: 'R2.d: wakelock requires a foreground activity',
            ),
          ),
          isFalse,
        );
      });

      test('returns true for unrelated platform errors', () {
        expect(
          service.shouldReportPlatformErrorFatally(
            PlatformException(code: 'OTHER', message: 'network down'),
          ),
          isTrue,
        );
      });

      test('returns false for AppErrorGuard log strings', () {
        expect(
          service.shouldReportPlatformErrorFatally(
            'Uncaught platform error: PlatformException(d, '
            'wakelock requires a foreground activity, null)',
          ),
          isFalse,
        );
      });
    });
  });
}
