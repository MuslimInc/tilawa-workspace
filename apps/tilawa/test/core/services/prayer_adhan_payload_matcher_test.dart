import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/services/prayer_adhan_notification_service.dart';
import 'package:tilawa/core/services/prayer_notification_config.dart';
import 'package:tilawa/core/services/prayer_notification_payload_classifier.dart';

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
    test('classifies scheduled local payload from service schedule path', () {
      final payload = jsonEncode({
        PrayerNotificationConfig.payloadTypeKey:
            PrayerNotificationConfig.payloadTypeValue,
        PrayerNotificationConfig.payloadPrayerKey: 'fajr',
        'prayer_name': 'fajr',
        'prayer_key': 'fajr',
        PrayerNotificationConfig.payloadDateKey: '2026-05-08',
        'scheduled_time_ms': 1700000000000,
        'adhan_enabled': true,
        'notification_id': 20000000,
      });
      expect(
        service.classifyPayloadKind(payload),
        NotificationPayloadKind.localPrayer,
      );
      expect(service.isPrayerPayload(payload), isTrue);
    });

    test('classifies whitespace-formatted local prayer payload', () {
      const payload =
          '{ "type": "prayer", "prayer": "fajr", "scheduled_time_ms": 1700000000000 }';
      expect(
        service.classifyPayloadKind(payload),
        NotificationPayloadKind.localPrayer,
      );
      expect(service.isPrayerPayload(payload), isTrue);
    });

    test('classifies generic FCM payload with only type prayer', () {
      const payload = '{"type":"prayer"}';
      expect(
        service.classifyPayloadKind(payload),
        NotificationPayloadKind.genericFcmPrayer,
      );
      expect(service.isPrayerPayload(payload), isFalse);
    });

    test(
      'type prayer + prayer identity is generic FCM and not local-owned',
      () {
        const payload = '{"type":"prayer","prayer":"fajr"}';
        expect(
          service.classifyPayloadKind(payload),
          NotificationPayloadKind.genericFcmPrayer,
        );
        expect(service.isPrayerPayload(payload), isFalse);
      },
    );

    test('does not match type prayer combined with weak date marker', () {
      final payload = jsonEncode({'type': 'prayer', 'date': '2026-05-08'});
      expect(
        service.classifyPayloadKind(payload),
        NotificationPayloadKind.genericFcmPrayer,
      );
      expect(service.isPrayerPayload(payload), isFalse);
    });

    test('does not match notification_id alone', () {
      final payload = jsonEncode({'notification_id': 2001});
      expect(
        service.classifyPayloadKind(payload),
        NotificationPayloadKind.unknown,
      );
      expect(service.isPrayerPayload(payload), isFalse);
    });

    test('does not match date alone', () {
      final payload = jsonEncode({'date': '2026-05-08'});
      expect(
        service.classifyPayloadKind(payload),
        NotificationPayloadKind.unknown,
      );
      expect(service.isPrayerPayload(payload), isFalse);
    });

    test(
      'classifies native adhan payload from MainActivity/method channel',
      () {
        final payload = jsonEncode({
          'type': 'prayer',
          'prayer': 'fajr',
          'prayer_name': 'fajr',
          'prayer_key': 'fajr',
          'scheduled_time_ms': 1700000000000,
          'scheduled_ms': 1700000000000,
          'notification_id': 20000000,
          'adhan_enabled': true,
          'is_adhan_playing': true,
        });
        expect(
          service.classifyPayloadKind(payload),
          NotificationPayloadKind.nativeAdhan,
        );
        expect(service.isPrayerPayload(payload), isTrue);
      },
    );

    test('classifies scheduled payload with scheduled_time_ms', () {
      final payload = jsonEncode({
        'type': 'prayer',
        'prayer': 'fajr',
        'scheduled_time_ms': 1700000000000,
      });
      expect(
        service.classifyPayloadKind(payload),
        NotificationPayloadKind.localPrayer,
      );
      expect(service.isPrayerPayload(payload), isTrue);
    });

    test('does not match schedule marker without explicit prayer typing', () {
      final payload = jsonEncode({'scheduled_ms': 1700000000000});
      expect(
        service.classifyPayloadKind(payload),
        NotificationPayloadKind.unknown,
      );
      expect(service.isPrayerPayload(payload), isFalse);
    });

    test('prayer_key without native marker stays unknown', () {
      const payload = '{ "prayer_key": "fajr" }';
      expect(
        service.classifyPayloadKind(payload),
        NotificationPayloadKind.unknown,
      );
      expect(service.isPrayerPayload(payload), isFalse);
    });

    test('does not match unrelated payload', () {
      final payload = jsonEncode({'type': 'downloads'});
      expect(
        service.classifyPayloadKind(payload),
        NotificationPayloadKind.unknown,
      );
      expect(service.isPrayerPayload(payload), isFalse);
    });

    test('falls back on invalid JSON if it contains prayer_key marker', () {
      const payload = 'invalid json but contains "prayer_key":"fajr"';
      expect(
        service.classifyPayloadKind(payload),
        NotificationPayloadKind.nativeAdhan,
      );
      expect(service.isPrayerPayload(payload), isTrue);
    });

    test('does not fall back on generic markers in invalid JSON', () {
      const payload = 'invalid json but contains "notification_id":123';
      expect(service.isPrayerPayload(payload), isFalse);
    });

    test('returns false for null or empty', () {
      expect(
        service.classifyPayloadKind(null),
        NotificationPayloadKind.unknown,
      );
      expect(service.classifyPayloadKind(''), NotificationPayloadKind.unknown);
      expect(service.isPrayerPayload(null), isFalse);
      expect(service.isPrayerPayload(''), isFalse);
    });
  });
}
