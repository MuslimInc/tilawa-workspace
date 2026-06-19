import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/core/services/android_adhan_alarm_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.tilawa.app/prayer_adhan');
  late AndroidAdhanAlarmPlayer player;
  late List<MethodCall> calls;

  setUp(() {
    player = AndroidAdhanAlarmPlayer(isSupportedOverride: true);
    calls = <MethodCall>[];
  });

  void stubChannel(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return handler(call);
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AndroidAdhanAlarmPlayer.getActiveAdhanPayload', () {
    test('returns null when native returns null', () async {
      stubChannel((call) => null);

      final result = await player.getActiveAdhanPayload();

      expect(result, isNull);
      expect(calls.single.method, 'getActiveAdhanPayload');
    });

    test('returns JSON-encoded payload when native returns a map', () async {
      stubChannel(
        (call) => <Object?, Object?>{
          'prayer_name': 'asr',
          'prayer_key': 'asr',
          'sound_name': 'adhan',
          'scheduled_time_ms': 1700000000000,
          'notification_id': 99,
          'adhan_enabled': true,
          'is_adhan_playing': true,
        },
      );

      final result = await player.getActiveAdhanPayload();

      expect(result, isNotNull);
      final Map<String, dynamic> decoded =
          jsonDecode(result!) as Map<String, dynamic>;
      expect(decoded['prayer_name'], 'asr');
      expect(decoded['prayer_key'], 'asr');
      expect(decoded['sound_name'], 'adhan');
      expect(decoded['scheduled_time_ms'], 1700000000000);
      expect(decoded['notification_id'], 99);
      expect(decoded['adhan_enabled'], isTrue);
      expect(decoded['is_adhan_playing'], isTrue);
    });

    test('returns null when native returns a non-map value', () async {
      stubChannel((call) => 'not-a-map');

      final result = await player.getActiveAdhanPayload();

      expect(result, isNull);
    });

    test('returns null when native throws PlatformException', () async {
      stubChannel((call) {
        throw PlatformException(code: 'BOOM');
      });

      final result = await player.getActiveAdhanPayload();

      expect(result, isNull);
    });

    test('normalises non-string keys into a string-keyed map', () async {
      stubChannel(
        (call) => <Object?, Object?>{
          1: 'one',
          'prayer_name': 'fajr',
        },
      );

      final result = await player.getActiveAdhanPayload();

      expect(result, isNotNull);
      final Map<String, dynamic> decoded =
          jsonDecode(result!) as Map<String, dynamic>;
      expect(decoded['1'], 'one');
      expect(decoded['prayer_name'], 'fajr');
    });
  });

  group('AndroidAdhanAlarmPlayer.isAdhanPlaying', () {
    test('returns true when native returns true', () async {
      stubChannel((call) => true);

      expect(await player.isAdhanPlaying(), isTrue);
      expect(calls.single.method, 'isAdhanPlaying');
    });

    test('returns false when native returns null', () async {
      stubChannel((call) => null);

      expect(await player.isAdhanPlaying(), isFalse);
    });

    test('returns false on PlatformException', () async {
      stubChannel((call) {
        throw PlatformException(code: 'FAIL');
      });

      expect(await player.isAdhanPlaying(), isFalse);
    });
  });

  group('AndroidAdhanAlarmPlayer scheduling', () {
    test(
      'scheduleAdhan forwards location and language to native channel',
      () async {
        stubChannel((call) => true);

        final ok = await player.scheduleAdhan(
          id: 2001,
          scheduledTime: DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000),
          prayerName: 'fajr',
          prayerKey: 'fajr',
          locationName: 'Cairo',
          languageCode: 'ar',
        );

        expect(ok, isTrue);
        expect(calls.single.method, 'scheduleAdhan');
        final args = calls.single.arguments as Map<dynamic, dynamic>;
        expect(args['locationName'], 'Cairo');
        expect(args['languageCode'], 'ar');
      },
    );

    test(
      'playAdhanNow forwards location and language to native channel',
      () async {
        stubChannel((call) => true);

        final ok = await player.playAdhanNow(
          id: 2001,
          prayerName: 'fajr',
          prayerKey: 'fajr',
          locationName: 'Cairo',
          languageCode: 'ar',
        );

        expect(ok, isTrue);
        expect(calls.single.method, 'playAdhanNow');
        final args = calls.single.arguments as Map<dynamic, dynamic>;
        expect(args['locationName'], 'Cairo');
        expect(args['languageCode'], 'ar');
      },
    );

    test(
      'persistPendingAlarms forwards location and language in alarm tuples',
      () async {
        stubChannel((call) => null);

        await player.persistPendingAlarms([
          PendingAdhanAlarm(
            id: 2001,
            prayerName: 'fajr',
            prayerKey: 'fajr',
            triggerAt: DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000),
            locationName: 'Cairo',
            languageCode: 'ar',
          ),
        ]);

        expect(calls.single.method, 'persistPendingAlarms');
        final args = calls.single.arguments as Map<dynamic, dynamic>;
        final alarms = args['alarms'] as List<dynamic>;
        expect(alarms.single['locationName'], 'Cairo');
        expect(alarms.single['languageCode'], 'ar');
      },
    );

    test('scheduleAdhan returns false on PlatformException', () async {
      stubChannel((call) {
        throw PlatformException(code: 'FAIL');
      });

      final ok = await player.scheduleAdhan(
        id: 1,
        scheduledTime: DateTime.now(),
        prayerName: 'fajr',
        prayerKey: 'fajr',
      );

      expect(ok, isFalse);
    });

    test('cancelAdhan invokes native channel', () async {
      stubChannel((call) => null);

      await player.cancelAdhan(42, prayerName: 'fajr');

      expect(calls.single.method, 'cancelAdhan');
      final args = calls.single.arguments as Map<dynamic, dynamic>;
      expect(args['id'], 42);
      expect(args['prayerName'], 'fajr');
    });

    test('cancelAllAdhans invokes native channel', () async {
      stubChannel((call) => null);

      await player.cancelAllAdhans();

      expect(calls.single.method, 'cancelAllAdhans');
    });

    test('stopCurrentAdhan invokes native channel', () async {
      stubChannel((call) => null);

      await player.stopCurrentAdhan();

      expect(calls.single.method, 'stopAdhan');
    });

    test('consumeNeedsRescheduleAfterBoot returns native flag', () async {
      stubChannel((call) => true);

      expect(await player.consumeNeedsRescheduleAfterBoot(), isTrue);
      expect(calls.single.method, 'consumeNeedsRescheduleAfterBoot');
    });

    test('markNeedsReschedule invokes native channel', () async {
      stubChannel((call) => null);

      await player.markNeedsReschedule();

      expect(calls.single.method, 'markNeedsReschedule');
    });

    test('scheduleAdhan omits blank optional fields', () async {
      stubChannel((call) => true);

      await player.scheduleAdhan(
        id: 1,
        scheduledTime: DateTime.now(),
        prayerName: 'fajr',
        prayerKey: 'fajr',
      );

      final args = calls.single.arguments as Map<dynamic, dynamic>;
      expect(args.containsKey('locationName'), isFalse);
      expect(args.containsKey('languageCode'), isFalse);
    });

    test('scheduleAdhan returns false when native returns false', () async {
      stubChannel((call) => false);

      final ok = await player.scheduleAdhan(
        id: 1,
        scheduledTime: DateTime.now(),
        prayerName: 'fajr',
        prayerKey: 'fajr',
      );

      expect(ok, isFalse);
    });

    test('playAdhanNow returns false on PlatformException', () async {
      stubChannel((call) {
        throw PlatformException(code: 'FAIL');
      });

      final ok = await player.playAdhanNow(
        id: 1,
        prayerName: 'fajr',
        prayerKey: 'fajr',
      );

      expect(ok, isFalse);
    });

    test('cancelAdhan swallows PlatformException', () async {
      stubChannel((call) {
        throw PlatformException(code: 'FAIL');
      });

      await expectLater(player.cancelAdhan(1), completes);
    });

    test('cancelAllAdhans swallows PlatformException', () async {
      stubChannel((call) {
        throw PlatformException(code: 'FAIL');
      });

      await expectLater(player.cancelAllAdhans(), completes);
    });

    test('persistPendingAlarms swallows PlatformException', () async {
      stubChannel((call) {
        throw PlatformException(code: 'FAIL');
      });

      await expectLater(
        player.persistPendingAlarms([
          PendingAdhanAlarm(
            id: 1,
            prayerName: 'fajr',
            prayerKey: 'fajr',
            triggerAt: DateTime.now(),
          ),
        ]),
        completes,
      );
    });

    test('clearPendingAlarms invokes native channel', () async {
      stubChannel((call) => null);

      await player.clearPendingAlarms();

      expect(calls.single.method, 'clearPendingAlarms');
    });

    test('clearPendingAlarms swallows PlatformException', () async {
      stubChannel((call) {
        throw PlatformException(code: 'FAIL');
      });

      await expectLater(player.clearPendingAlarms(), completes);
    });

    test(
      'consumeNeedsRescheduleAfterBoot returns false on PlatformException',
      () async {
        stubChannel((call) {
          throw PlatformException(code: 'FAIL');
        });

        expect(await player.consumeNeedsRescheduleAfterBoot(), isFalse);
      },
    );

    test('markNeedsReschedule swallows PlatformException', () async {
      stubChannel((call) {
        throw PlatformException(code: 'FAIL');
      });

      await expectLater(player.markNeedsReschedule(), completes);
    });

    test('isIgnoringBatteryOptimizations returns native value', () async {
      stubChannel((call) => true);

      expect(await player.isIgnoringBatteryOptimizations(), isTrue);
      expect(calls.single.method, 'isIgnoringBatteryOptimizations');
    });

    test(
      'isIgnoringBatteryOptimizations returns false on PlatformException',
      () async {
        stubChannel((call) {
          throw PlatformException(code: 'FAIL');
        });

        expect(await player.isIgnoringBatteryOptimizations(), isFalse);
      },
    );

    test(
      'requestIgnoreBatteryOptimizations swallows PlatformException',
      () async {
        stubChannel((call) {
          throw PlatformException(code: 'FAIL');
        });

        await expectLater(
          player.requestIgnoreBatteryOptimizations(),
          completes,
        );
      },
    );

    test('manufacturer returns native value', () async {
      stubChannel((call) => 'Google');

      expect(await player.manufacturer(), 'Google');
    });

    test('manufacturer returns null on PlatformException', () async {
      stubChannel((call) {
        throw PlatformException(code: 'FAIL');
      });

      expect(await player.manufacturer(), isNull);
    });

    test('stopCurrentAdhan swallows PlatformException', () async {
      stubChannel((call) {
        throw PlatformException(code: 'FAIL');
      });

      await expectLater(player.stopCurrentAdhan(), completes);
    });

    test(
      'pullPendingNotificationTapPayload returns payload from native map',
      () async {
        stubChannel((call) => {'payload': 'pending-1'});

        expect(await player.pullPendingNotificationTapPayload(), 'pending-1');
        expect(calls.single.method, 'consumePendingNotificationTap');
      },
    );

    test(
      'pullPendingNotificationTapPayload returns null for non-map response',
      () async {
        stubChannel((call) => 'not-a-map');

        expect(await player.pullPendingNotificationTapPayload(), isNull);
      },
    );

    test(
      'pullPendingNotificationTapPayload returns null on PlatformException',
      () async {
        stubChannel((call) {
          throw PlatformException(code: 'FAIL');
        });

        expect(await player.pullPendingNotificationTapPayload(), isNull);
      },
    );

    test(
      'pullPendingNotificationTapPayload returns null when not supported',
      () async {
        final unsupported = AndroidAdhanAlarmPlayer(isSupportedOverride: false);

        expect(await unsupported.pullPendingNotificationTapPayload(), isNull);
      },
    );

    test(
      'flushPendingNotificationTap emits buffered payload when stream is listened',
      () async {
        stubChannel((call) {
          if (call.method == 'consumePendingNotificationTap') {
            return {'payload': 'flushed-payload'};
          }
          if (call.method == 'ackNotificationTap') {
            return null;
          }
          return null;
        });

        final payloads = <String>[];
        player.onNotificationTapped.listen(payloads.add);
        await Future<void>.delayed(Duration.zero);

        expect(payloads, ['flushed-payload']);
      },
    );
  });

  group('AndroidAdhanAlarmPlayer.isSupported', () {
    test('returns false when override is false', () {
      final unsupported = AndroidAdhanAlarmPlayer(isSupportedOverride: false);
      expect(unsupported.isSupported, isFalse);
    });

    test(
      'scheduleAdhan returns false immediately when not supported',
      () async {
        final unsupported = AndroidAdhanAlarmPlayer(isSupportedOverride: false);

        expect(
          await unsupported.scheduleAdhan(
            id: 1,
            scheduledTime: DateTime.now(),
            prayerName: 'fajr',
            prayerKey: 'fajr',
          ),
          isFalse,
        );
      },
    );
  });
}
