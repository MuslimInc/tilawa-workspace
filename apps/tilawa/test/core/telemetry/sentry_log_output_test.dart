import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/crash_reporting_context.dart';
import 'package:tilawa/core/telemetry/sentry_log_output.dart';

void main() {
  group('SentryLogOutput', () {
    test('formatBody includes error when present', () {
      final LogEvent event = LogEvent(
        Level.error,
        'Download failed',
        error: StateError('network'),
      );

      expect(
        SentryLogOutput.formatBody(event),
        'Download failed: Bad state: network',
      );
    });

    test('buildAttributes captures error type and stack trace', () {
      final LogEvent event = LogEvent(
        Level.warning,
        'retry',
        error: ArgumentError('bad'),
        stackTrace: StackTrace.current,
      );

      final Map<String, SentryAttribute> attributes =
          SentryLogOutput.buildAttributes(event);

      expect(attributes['error_type']?.value, 'ArgumentError');
      expect(attributes['stack_trace']?.value, isA<String>());
    });

    test('truncateStackTrace caps long traces', () {
      final StackTrace longTrace = StackTrace.fromString(
        List<String>.generate(20, (int i) => '#$i frame').join('\n'),
      );

      final String truncated = SentryLogOutput.truncateStackTrace(longTrace);

      expect(truncated, contains('… (10 more frames)'));
      expect(truncated.split('\n').length, lessThan(20));
    });
  });

  group('filterEmulatorLogsForMode', () {
    final SentryLog sampleLog = SentryLog(
      timestamp: DateTime.utc(2026),
      level: SentryLogLevel.warn,
      body: 'test',
      attributes: <String, SentryAttribute>{},
    );

    test('drops logs in release when deviceKind is emulator', () {
      expect(
        CrashReportingContext.filterEmulatorLogsForMode(
          log: sampleLog,
          releaseMode: true,
          deviceKind: 'emulator',
        ),
        isNull,
      );
    });

    test('keeps logs in release for physical devices', () {
      expect(
        CrashReportingContext.filterEmulatorLogsForMode(
          log: sampleLog,
          releaseMode: true,
          deviceKind: 'physical',
        ),
        sampleLog,
      );
    });

    test('keeps logs in debug regardless of deviceKind', () {
      expect(
        CrashReportingContext.filterEmulatorLogsForMode(
          log: sampleLog,
          releaseMode: false,
          deviceKind: 'emulator',
        ),
        sampleLog,
      );
    });
  });
}
