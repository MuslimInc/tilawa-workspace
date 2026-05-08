import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/services/prayer_adhan_notification_service.dart';
import 'package:tilawa/core/services/prayer_notification_config.dart';
import 'prayer_adhan_notification_service_test.mocks.dart';

void main() {
  late PrayerAdhanNotificationService service;

  setUp(() {
    service = PrayerAdhanNotificationService(
      MockSharedPreferencesAsync(),
      MockINotificationDispatcher(),
      MockNavigationService(),
      MockAnalyticsService(),
      MockIAdhanAlarmPlayer(),
      MockNotificationPermissionService(),
    );
  });

  group('PrayerAdhanNotificationService matcher logic', () {
    test('matches compact JSON', () {
      final payload = jsonEncode({
        PrayerNotificationConfig.payloadTypeKey:
            PrayerNotificationConfig.payloadTypeValue,
        'prayer': 'fajr',
      });
      expect(service.isPrayerPayload(payload), isTrue);
    });

    test('matches whitespace-formatted JSON', () {
      const payload = '{ "type": "prayer", "prayer": "fajr" }';
      expect(service.isPrayerPayload(payload), isTrue);
    });

    test('matches native Adhan payload with prayer_key', () {
      final payload = jsonEncode({'prayer_key': 'fajr'});
      expect(service.isPrayerPayload(payload), isTrue);
    });

    test('matches scheduled payload with scheduled_time_ms', () {
      final payload = jsonEncode({'scheduled_time_ms': 1700000000000});
      expect(service.isPrayerPayload(payload), isTrue);
    });

    test('matches payload with scheduled_ms', () {
      final payload = jsonEncode({'scheduled_ms': 1700000000000});
      expect(service.isPrayerPayload(payload), isTrue);
    });

    test('matches payload with notification_id', () {
      final payload = jsonEncode({'notification_id': 2001});
      expect(service.isPrayerPayload(payload), isTrue);
    });

    test('matches payload with adhan_enabled', () {
      final payload = jsonEncode({'adhan_enabled': true});
      expect(service.isPrayerPayload(payload), isTrue);
    });

    test('matches payload with is_adhan_playing', () {
      final payload = jsonEncode({'is_adhan_playing': true});
      expect(service.isPrayerPayload(payload), isTrue);
    });

    test('matches payload with date marker', () {
      final payload = jsonEncode({'date': '2024-05-08'});
      expect(service.isPrayerPayload(payload), isTrue);
    });

    test('does not match unrelated payload', () {
      final payload = jsonEncode({'type': 'downloads'});
      expect(service.isPrayerPayload(payload), isFalse);
    });

    test(
      'does not throw and falls back on invalid JSON if it contains marker',
      () {
        const payload = 'invalid json but contains "type":"prayer"';
        expect(service.isPrayerPayload(payload), isTrue);
      },
    );

    test('does not match invalid JSON without markers', () {
      const payload = 'not a json';
      expect(service.isPrayerPayload(payload), isFalse);
    });

    test('returns false for null or empty', () {
      expect(service.isPrayerPayload(null), isFalse);
      expect(service.isPrayerPayload(''), isFalse);
    });
  });
}
