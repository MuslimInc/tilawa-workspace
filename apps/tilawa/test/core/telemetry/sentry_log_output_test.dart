import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/crash_reporting_context.dart';
import 'package:tilawa/core/telemetry/sentry_log_output.dart';

import 'sentry_test_support.dart';

void main() {
  group('SentryLogOutput', () {
    test('forwardingEnabled is false outside release builds', () {
      expect(kReleaseMode, isFalse);
      expect(SentryLogOutput.forwardingEnabled, isFalse);
    });

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

    test('formatBody uses error text when message is empty', () {
      final LogEvent event = LogEvent(
        Level.error,
        null,
        error: StateError('boom'),
      );

      expect(SentryLogOutput.formatBody(event), 'Bad state: boom');
    });

    test('formatBody returns message when error is absent', () {
      final LogEvent event = LogEvent(Level.info, 'hello');
      expect(SentryLogOutput.formatBody(event), 'hello');
    });

    test('buildAttributes omits optional fields when absent', () {
      expect(
        SentryLogOutput.buildAttributes(LogEvent(Level.info, 'x')),
        isEmpty,
      );
    });

    test('truncateStackTrace keeps short traces unchanged', () {
      final StackTrace trace = StackTrace.fromString('#0 frame');
      expect(SentryLogOutput.truncateStackTrace(trace), trace.toString());
    });

    test('truncateStackTrace omits frames beyond the cap', () {
      final StackTrace trace = StackTrace.fromString(
        List<String>.generate(15, (int index) => '#$index frame').join('\n'),
      );

      final String truncated = SentryLogOutput.truncateStackTrace(trace);

      expect(truncated, contains('#9 frame'));
      expect(truncated, contains('5 more frames'));
      expect(truncated, isNot(contains('#10 frame')));
    });

    test('output ignores sub-warning events', () {
      SentryLogOutput().output(
        OutputEvent(
          LogEvent(Level.info, 'ignored'),
          <String>['ignored'],
        ),
      );
    });

    test('output ignores events when forwarding is disabled', () {
      expect(kReleaseMode, isFalse);
      SentryLogOutput().output(
        OutputEvent(
          LogEvent(Level.error, 'still ignored in tests'),
          <String>['still ignored in tests'],
        ),
      );
    });

    group('dispatchForTesting', () {
      setUpAll(() async {
        await ensureSentryInitializedForTests();
      });

      test('routes trace debug info and error levels', () {
        for (final Level level in <Level>[
          Level.trace,
          Level.debug,
          Level.info,
          Level.error,
        ]) {
          expect(
            () => SentryLogOutput.dispatchForTesting(
              level: level,
              body: 'level-$level',
              attributes: const <String, SentryAttribute>{},
            ),
            returnsNormally,
          );
        }
      });

      test('routes warning fatal verbose and off levels', () {
        for (final Level level in <Level>[
          Level.warning,
          Level.fatal,
          // ignore: deprecated_member_use
          Level.verbose,
          Level.all,
          Level.off,
          // ignore: deprecated_member_use
          Level.nothing,
        ]) {
          expect(
            () => SentryLogOutput.dispatchForTesting(
              level: level,
              body: 'level-$level',
              attributes: const <String, SentryAttribute>{},
            ),
            returnsNormally,
          );
        }
      });
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
