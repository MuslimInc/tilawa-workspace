import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/notifications/presentation/services/fcm_notification_handler_service.dart';
import 'package:tilawa/router/app_router_config.dart';

void main() {
  group('FCMNotificationHandlerService route resolution', () {
    test('resolves reciter deep links to the valid reciter route', () {
      final location = FCMNotificationHandlerService.resolveLocation({
        'type': 'reciter',
        'data': '7',
      });

      expect(location, ReciterDetailsRoute(reciterId: '7').location);
    });

    test('accepts admin payload aliases for quran deep links', () {
      final normalized = FCMNotificationHandlerService.normalizePayloadForTest({
        'actionType': 'quran',
        'actionData': '2',
      });

      expect(normalized['type'], 'quran');
      expect(normalized['data'], '2');
      expect(
        FCMNotificationHandlerService.resolveLocation(normalized),
        QuranReaderRoute(surahNumber: 2).location,
      );
    });

    test(
      'falls back to athkar categories when detail payload is incomplete',
      () {
        final location = FCMNotificationHandlerService.resolveLocation({
          'type': 'athkar',
        });

        expect(location, const AthkarCategoriesRoute().location);
      },
    );

    test('routes to athkar details when category id and name are present', () {
      final location = FCMNotificationHandlerService.resolveLocation({
        'categoryId': '1',
        'categoryName': 'Morning Athkar',
      });

      expect(
        location,
        const AthkarDetailsRoute(
          categoryId: 1,
          categoryName: 'Morning Athkar',
        ).location,
      );
    });

    test('routes settings notifications correctly', () {
      final location = FCMNotificationHandlerService.resolveLocation({
        'type': 'settings',
      });

      expect(location, const SettingsRoute().location);
    });
  });
}
