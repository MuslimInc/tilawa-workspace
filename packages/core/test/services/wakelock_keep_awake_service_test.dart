import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/services/wakelock_keep_awake_service.dart';

void main() {
  group('WakelockKeepAwakeService', () {
    late WakelockKeepAwakeService service;

    setUp(() {
      service = WakelockKeepAwakeService();
    });

    test('enable sets internal state when plugin succeeds', () async {
      var enableCalls = 0;
      service.wakelockEnable = () async {
        enableCalls++;
      };

      await service.enable();

      expect(enableCalls, 1);
      expect(await service.isEnabled, isTrue);
    });

    test('enable is idempotent when already enabled', () async {
      var enableCalls = 0;
      service.wakelockEnable = () async {
        enableCalls++;
      };

      await service.enable();
      await service.enable();

      expect(enableCalls, 1);
      expect(await service.isEnabled, isTrue);
    });

    test(
      'enable rethrows unrelated PlatformException',
      () async {
        service.wakelockEnable = () async {
          throw PlatformException(code: 'OTHER', message: 'fail');
        };

        await expectLater(service.enable(), throwsA(isA<PlatformException>()));
        expect(await service.isEnabled, isFalse);
      },
    );

    test(
      'disable swallows NoActivityException and clears internal state',
      () async {
        service.wakelockEnable = () async {};
        await service.enable();
        expect(await service.isEnabled, isTrue);

        service.wakelockDisable = () async {
          throw PlatformException(
            code: 'NoActivityException',
            message: 'wakelock requires a foreground activity',
          );
        };

        await expectLater(service.disable(), completes);
        expect(await service.isEnabled, isFalse);
      },
    );

    test(
      'disable swallows any PlatformException and clears internal state',
      () async {
        service.wakelockEnable = () async {};
        await service.enable();
        expect(await service.isEnabled, isTrue);

        service.wakelockDisable = () async {
          throw PlatformException(code: 'OTHER', message: 'fail');
        };

        await expectLater(service.disable(), completes);
        expect(await service.isEnabled, isFalse);
      },
    );

    test('disable is idempotent when already disabled', () async {
      var disableCalls = 0;
      service.wakelockDisable = () async {
        disableCalls++;
      };

      await service.disable();
      expect(disableCalls, 0);
    });

    test(
      'enable swallows NoActivityException without updating state',
      () async {
        service.wakelockEnable = () async {
          throw PlatformException(
            code: 'NoActivityException',
            message: 'wakelock requires a foreground activity',
          );
        };

        await expectLater(service.enable(), completes);
        expect(await service.isEnabled, isFalse);
      },
    );

    test(
      'enable swallows obfuscated release code d with wakelock message',
      () async {
        service.wakelockEnable = () async {
          throw PlatformException(
            code: 'd',
            message: 'R2.d: wakelock requires a foreground activity',
          );
        };

        await expectLater(service.enable(), completes);
        expect(await service.isEnabled, isFalse);
      },
    );
  });

  group('platformExceptionDescription', () {
    test('joins message details and toString', () {
      final PlatformException exception = PlatformException(
        code: 'd',
        message: 'wakelock requires a foreground activity',
        details: 'extra',
      );

      expect(
        platformExceptionDescription(exception),
        contains('wakelock requires a foreground activity'),
      );
      expect(platformExceptionDescription(exception), contains('extra'));
    });
  });

  group('isNoActivityPlatformException', () {
    test('matches NoActivityException code', () {
      expect(
        isNoActivityPlatformException(
          PlatformException(
            code: 'NoActivityException',
            message: 'wakelock requires a foreground activity',
          ),
        ),
        isTrue,
      );
    });

    test('rejects unrelated platform exception codes and messages', () {
      expect(
        isNoActivityPlatformException(
          PlatformException(code: 'OTHER', message: 'fail'),
        ),
        isFalse,
      );
    });

    test('matches foreground activity message without NoActivity code', () {
      expect(
        isNoActivityPlatformException(
          PlatformException(
            code: 'OTHER',
            message: 'wakelock requires a foreground activity',
          ),
        ),
        isTrue,
      );
    });

    test('matches obfuscated code d when description mentions wakelock', () {
      expect(
        isNoActivityPlatformException(
          PlatformException(
            code: 'd',
            message: 'R2.d: wakelock requires a foreground activity',
          ),
        ),
        isTrue,
      );
    });

    test('rejects obfuscated code d without wakelock context', () {
      expect(
        isNoActivityPlatformException(
          PlatformException(code: 'd', message: 'unrelated failure'),
        ),
        isFalse,
      );
    });
  });

  group('isIgnorableWakelockPlatformNoise', () {
    test('matches PlatformException from FLUTTER-AK', () {
      expect(
        isIgnorableWakelockPlatformNoise(
          PlatformException(
            code: 'd',
            message: 'R2.d: wakelock requires a foreground activity',
          ),
        ),
        isTrue,
      );
    });

    test('matches AppErrorGuard log string', () {
      expect(
        isIgnorableWakelockPlatformNoise(
          'Uncaught platform error: PlatformException(d, '
          'R2.d: wakelock requires a foreground activity, null)',
        ),
        isTrue,
      );
    });

    test('rejects unrelated errors', () {
      expect(
        isIgnorableWakelockPlatformNoise(
          PlatformException(code: 'OTHER', message: 'network down'),
        ),
        isFalse,
      );
    });
  });
}
