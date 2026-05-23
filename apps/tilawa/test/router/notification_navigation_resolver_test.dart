import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/notification_navigation_resolver.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

void main() {
  group('NotificationNavigationResolver', () {
    test('resolveLocation maps settings notification to settings route', () {
      final String location = NotificationNavigationResolver.resolveLocation(
        const {'type': 'settings'},
      );

      expect(location, const SettingsRoute().location);
    });

    test('resolveLocation maps reciter notification to reciter details', () {
      final String location = NotificationNavigationResolver.resolveLocation(
        const {'type': 'reciter', 'reciterId': '7'},
      );

      expect(location, const ReciterDetailsRoute(reciterId: '7').location);
    });

    test('resolveExtra returns embedded reciter entity for reciter routes', () {
      final String location = const ReciterDetailsRoute(reciterId: '9').location;

      final Object? extra = NotificationNavigationResolver.resolveExtra(
        <String, dynamic>{
          'type': 'reciter',
          'reciterId': '9',
          'reciter': <String, dynamic>{
            'id': 9,
            'name': 'Test',
            'letter': 'T',
            'date': '',
            'moshaf': <dynamic>[],
          },
        },
        location,
      );

      expect(extra, isA<ReciterEntity>());
      expect((extra! as ReciterEntity).id, 9);
    });
  });
}
