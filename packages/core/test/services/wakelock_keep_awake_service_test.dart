import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/services/wakelock_keep_awake_service.dart';

void main() {
  group('WakelockKeepAwakeService', () {
    late WakelockKeepAwakeService service;

    setUp(() {
      service = WakelockKeepAwakeService();
    });

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
  });
}
