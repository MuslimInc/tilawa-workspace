import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/services/notification_dispatcher.dart';
import 'package:tilawa/features/downloads/data/services/download_notification_service.dart';

void main() {
  group('NotificationDispatcher ID range routing', () {
    late NotificationDispatcher dispatcher;
    NotificationResponse? handledResponse;

    setUp(() {
      dispatcher = NotificationDispatcher();
      handledResponse = null;
      dispatcher.registerIdRangeHandler(
        serviceId: 'downloads',
        minIdInclusive: DownloadNotificationService.notificationIdOffset,
        maxIdExclusive:
            DownloadNotificationService.notificationIdRangeEndExclusive,
        handler: (NotificationResponse response) async {
          handledResponse = response;
        },
      );
    });

    test('routes download notification IDs without payload', () async {
      final bool routed = await dispatcher.routeNotificationForTest(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 100003,
        ),
      );

      expect(routed, isTrue);
      expect(handledResponse?.id, 100003);
      expect(handledResponse?.payload, isNull);
    });

    test('does not route IDs outside the registered range', () async {
      final bool routed = await dispatcher.routeNotificationForTest(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 2001,
        ),
      );

      expect(routed, isFalse);
      expect(handledResponse, isNull);
    });

    test(
      'prefers athkar payload handler over download id range for debug ids',
      () async {
        NotificationResponse? downloadHandled;
        NotificationResponse? athkarHandled;

        dispatcher.registerPayloadHandler(
          serviceId: 'athkar',
          matcher: (String? payload) =>
              payload?.startsWith('morning_athkar_') ?? false,
          handler: (NotificationResponse response) async {
            athkarHandled = response;
          },
        );

        final bool routed = await dispatcher.routeNotificationForTest(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            id: 900001,
            payload: 'morning_athkar_debug_lab',
          ),
        );

        expect(routed, isTrue);
        expect(athkarHandled?.id, 900001);
        expect(downloadHandled, isNull);
      },
    );

    test(
      'prefers fcm payload handler over download id range for prayer json',
      () async {
        NotificationResponse? downloadHandled;
        NotificationResponse? fcmHandled;

        dispatcher.registerPayloadHandler(
          serviceId: 'fcm_service',
          matcher: (String? payload) {
            if (payload == null) {
              return false;
            }
            try {
              final dynamic decoded = jsonDecode(payload);
              return decoded is Map && decoded['type'] == 'prayer';
            } catch (_) {
              return false;
            }
          },
          handler: (NotificationResponse response) async {
            fcmHandled = response;
          },
        );

        final bool routed = await dispatcher.routeNotificationForTest(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            id: 900003,
            payload:
                '{"type":"prayer","prayer_key":"fajr","prayer_name":"fajr"}',
          ),
        );

        expect(routed, isTrue);
        expect(fcmHandled?.id, 900003);
        expect(downloadHandled, isNull);
      },
    );
  });
}
