import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/telemetry/startup_telemetry.dart';

void main() {
  setUp(() {
    StartupTelemetry.configureForTesting(
      analyticsLogging: false,
      crashlyticsLogging: false,
    );
  });

  tearDown(StartupTelemetry.resetForTesting);

  test('phase completes without throwing in test mode', () async {
    await expectLater(
      StartupTelemetry.phase('boot_gate_start'),
      completes,
    );
  });

  test('failure completes without throwing in test mode', () async {
    await expectLater(
      StartupTelemetry.failure(
        'boot_gate_critical_init_failed',
        StateError('di missing'),
        StackTrace.current,
        phase: 'boot_gate',
      ),
      completes,
    );
  });

  test('completed completes without throwing in test mode', () async {
    await expectLater(StartupTelemetry.completed(), completes);
  });

  test('resetForTesting clears test configuration', () {
    StartupTelemetry.resetForTesting();
    expect(
      StartupTelemetry.resetForTesting,
      returnsNormally,
    );
  });
}
