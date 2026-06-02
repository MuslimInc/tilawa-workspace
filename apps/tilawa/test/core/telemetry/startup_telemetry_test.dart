import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/telemetry/startup_health_log_sink.dart';
import 'package:tilawa/core/telemetry/startup_telemetry.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';

void main() {
  late InMemoryStartupHealthLogSink sink;

  setUp(() {
    sink = InMemoryStartupHealthLogSink();
    StartupTelemetry.configureForTesting(
      healthLogSink: sink,
      firestoreLogging: true,
      analyticsLogging: false,
      crashlyticsLogging: false,
    );
  });

  tearDown(StartupTelemetry.resetForTesting);

  test('phase writes structured backend log entry', () async {
    await StartupTelemetry.phase('boot_gate_start');

    expect(sink.entries, hasLength(1));
    final Map<String, Object?> entry = sink.entries.single;
    expect(entry['event'], AnalyticsEvents.startupPhase);
    expect(entry['phase'], 'boot_gate_start');
    expect(entry['level'], 'info');
    expect(entry['session_id'], isNotNull);
    expect(entry['elapsed_ms'], isA<int>());
  });

  test('failure writes error backend log entry', () async {
    await StartupTelemetry.failure(
      'boot_gate_critical_init_failed',
      StateError('di missing'),
      StackTrace.current,
      phase: 'boot_gate',
    );

    expect(sink.entries, hasLength(1));
    final Map<String, Object?> entry = sink.entries.single;
    expect(entry['event'], AnalyticsEvents.startupFailed);
    expect(entry['level'], 'error');
    expect(entry['reason'], 'boot_gate_critical_init_failed');
    expect(entry['phase'], 'boot_gate');
    expect(entry['error_type'], 'StateError');
  });

  test('completed writes startup_completed entry', () async {
    await StartupTelemetry.completed();

    expect(sink.entries, hasLength(1));
    expect(sink.entries.single['event'], AnalyticsEvents.startupCompleted);
  });
}
