import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_startup_readiness.dart';

void main() {
  late AppStartupReadiness readiness;

  setUp(() {
    readiness = AppStartupReadiness();
  });

  test('waitUntilReady skips work when prepareShell is false', () async {
    await readiness.waitUntilReady(prepareShell: false);
    expect(readiness.shellPrepComplete, isFalse);
  });

  test('waitUntilReady marks shell prep complete for home path', () async {
    await readiness.waitUntilReady(prepareShell: true);
    expect(readiness.shellPrepComplete, isTrue);
    expect(readiness.timedOut, isFalse);
  });

  test('second waitUntilReady is a no-op when already complete', () async {
    await readiness.waitUntilReady(prepareShell: true);
    await readiness.waitUntilReady(prepareShell: true);
    expect(readiness.shellPrepComplete, isTrue);
  });

  test('resetForTesting clears flags', () async {
    await readiness.waitUntilReady(prepareShell: true);
    readiness.resetForTesting();
    expect(readiness.shellPrepComplete, isFalse);
    expect(readiness.timedOut, isFalse);
  });
}
