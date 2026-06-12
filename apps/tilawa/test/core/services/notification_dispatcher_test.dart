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
        maxIdExclusive: DownloadNotificationService.notificationIdRangeEndExclusive,
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
  });
}
