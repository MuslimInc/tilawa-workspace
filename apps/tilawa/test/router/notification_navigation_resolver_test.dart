import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/notification_navigation_resolver.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

void main() {
  group('NotificationNavigationResolver', () {
    test('resolveLocation maps reciter type', () {
      final String location = NotificationNavigationResolver.resolveLocation(
        const {'type': 'reciter', 'data': '42'},
      );
      expect(location, '/reciter/42');
    });

    test('resolveExtra returns embedded reciter map', () {
      const reciter = ReciterEntity(
        id: 42,
        name: 'Test Reciter',
        letter: 'T',
        date: '2024-01-01',
        moshaf: [],
      );
      final Object? extra = NotificationNavigationResolver.resolveExtra(
        {
          'type': 'reciter',
          'reciter': {
            'id': 42,
            'name': 'Test Reciter',
            'letter': 'T',
            'date': '2024-01-01',
            'moshaf': <Map<String, dynamic>>[],
          },
        },
        '/reciter/42',
      );
      expect(extra, reciter);
    });

    test('resolveExtra returns prayer payload string', () {
      final String location = const PrayerNotificationStatusRoute().location;
      final Object? extra = NotificationNavigationResolver.resolveExtra(
        {'payload': '{"prayer_name":"asr"}'},
        location,
      );
      expect(extra, '{"prayer_name":"asr"}');
    });
  });
}
