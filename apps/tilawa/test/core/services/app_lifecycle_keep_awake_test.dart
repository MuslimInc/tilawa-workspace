import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/services/app_lifecycle_keep_awake.dart';
import 'package:tilawa_core/services/interfaces/keep_awake_service.dart';

class _FakeKeepAwakeService implements KeepAwakeService {
  int enableCalls = 0;
  int disableCalls = 0;

  @override
  Future<void> disable() async {
    disableCalls++;
  }

  @override
  Future<void> enable() async {
    enableCalls++;
  }

  @override
  Future<bool> get isEnabled async => enableCalls > disableCalls;
}

void main() {
  group('AppLifecycleKeepAwake', () {
    late _FakeKeepAwakeService keepAwakeService;

    setUp(() {
      keepAwakeService = _FakeKeepAwakeService();
    });

    testWidgets('defers enable until the next frame on resume', (
      WidgetTester tester,
    ) async {
      AppLifecycleKeepAwake.handleStateChange(
        state: AppLifecycleState.resumed,
        keepAwakeService: keepAwakeService,
      );

      expect(keepAwakeService.enableCalls, 0);

      await tester.pump();

      expect(keepAwakeService.enableCalls, 1);
      expect(keepAwakeService.disableCalls, 0);
    });

    test('disables immediately on paused', () {
      AppLifecycleKeepAwake.handleStateChange(
        state: AppLifecycleState.paused,
        keepAwakeService: keepAwakeService,
      );

      expect(keepAwakeService.disableCalls, 1);
      expect(keepAwakeService.enableCalls, 0);
    });

    test('disables immediately on inactive', () {
      AppLifecycleKeepAwake.handleStateChange(
        state: AppLifecycleState.inactive,
        keepAwakeService: keepAwakeService,
      );

      expect(keepAwakeService.disableCalls, 1);
    });

    test('disables immediately on detached', () {
      AppLifecycleKeepAwake.handleStateChange(
        state: AppLifecycleState.detached,
        keepAwakeService: keepAwakeService,
      );

      expect(keepAwakeService.disableCalls, 1);
    });

    test('disables immediately on hidden', () {
      AppLifecycleKeepAwake.handleStateChange(
        state: AppLifecycleState.hidden,
        keepAwakeService: keepAwakeService,
      );

      expect(keepAwakeService.disableCalls, 1);
    });
  });
}
