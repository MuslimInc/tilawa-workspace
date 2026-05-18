import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
