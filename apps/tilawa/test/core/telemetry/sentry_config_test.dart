import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/crash_reporting_context.dart';
import 'package:tilawa/core/telemetry/sentry_config.dart';

void main() {
  group('SentryConfig', () {
    test('applyFlutterOptions wires Tilawa defaults', () {
      final SentryFlutterOptions options = SentryFlutterOptions();

      SentryConfig.applyFlutterOptions(
        options,
        autoInitializeNativeSdk: false,
      );

      expect(options.dsn, kProfileMode ? '' : SentryConfig.dsn);
      expect(options.environment, kReleaseMode ? 'production' : 'development');
      expect(options.debug, kDebugMode);
      expect(options.enableLogs, kReleaseMode);
      expect(options.autoInitializeNativeSdk, isFalse);
      expect(
        options.beforeSend,
        CrashReportingContext.filterBeforeSend,
      );
      expect(
        options.beforeSendLog,
        CrashReportingContext.filterBeforeSendLog,
      );
    });
  });
}
