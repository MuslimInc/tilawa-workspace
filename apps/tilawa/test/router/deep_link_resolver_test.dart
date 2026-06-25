import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/navigation/navigation_source.dart';
import 'package:tilawa/core/navigation/notification_destination.dart';
import 'package:tilawa/features/athkar/domain/constants/tasbeeh_constants.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/deep_link_resolver.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  const DeepLinkResolver resolver = DeepLinkResolver();

  group('DeepLinkResolver.resolveLocation', () {
    test('maps settings notification to settings route', () {
      expect(
        DeepLinkResolver.resolveLocation(const {'type': 'settings'}),
        const SettingsRoute().location,
      );
    });

    test('maps reciter notification to reciter details', () {
      expect(
        DeepLinkResolver.resolveLocation(
          const {'type': 'reciter', 'reciterId': '7'},
        ),
        const ReciterDetailsRoute(reciterId: '7').location,
      );
    });

    test('maps quran notification to reader and validates surah range', () {
      expect(
        DeepLinkResolver.resolveLocation(
          const {'type': 'quran', 'surahNumber': '2'},
        ),
        const QuranReaderRoute(surahNumber: 2).location,
      );
      // Out-of-range falls back to the Quran hub.
      expect(
        DeepLinkResolver.resolveLocation(
          const {'type': 'quran', 'surahNumber': '999'},
        ),
        const QuranIndexRoute().location,
      );
    });

    test('infers type from well-known keys and legacy aliases', () {
      expect(
        DeepLinkResolver.resolveLocation(const {'reciterId': '9'}),
        const ReciterDetailsRoute(reciterId: '9').location,
      );
      expect(
        DeepLinkResolver.resolveLocation(
          const {'actionType': 'settings'},
        ),
        const SettingsRoute().location,
      );
    });

    test('maps tasbeeh notification to tasbeeh route with dhikrId', () {
      expect(
        DeepLinkResolver.resolveLocation(
          const {'type': 'tasbeeh', 'dhikrId': 'abc'},
        ),
        const TasbeehRoute(dhikrId: 'abc').location,
      );
    });

    test('maps tasbeeh notification without dhikrId to tasbeeh home', () {
      expect(
        DeepLinkResolver.resolveLocation(const {'type': 'tasbeeh'}),
        const TasbeehRoute().location,
      );
    });

    test('athkar deep link carries source=notification', () {
      final String location = DeepLinkResolver.resolveLocation(
        const {'type': 'athkar', 'categoryId': '1', 'categoryName': 'الصباح'},
      );
      final Uri uri = Uri.parse(location);
      expect(uri.path, '/athkar/1');
      expect(
        uri.queryParameters['source'],
        NavigationSource.notification.wireValue,
      );
    });

    test(
      'maps quran_session notification with sessionId to session detail',
      () {
        expect(
          DeepLinkResolver.resolveLocation(
            const {'type': 'quran_session', 'sessionId': '1234'},
          ),
          QuranSessionsRoutes.sessionDetail.replaceFirst(':bookingId', '1234'),
        );
      },
    );

    test(
      'maps incoming_quran_session_call notification with bookingId to session detail',
      () {
        expect(
          DeepLinkResolver.resolveLocation(
            const {'type': 'incoming_quran_session_call', 'bookingId': '5678'},
          ),
          QuranSessionsRoutes.sessionDetail.replaceFirst(':bookingId', '5678'),
        );
      },
    );

    test(
      'maps quran_session notification without sessionId to my sessions',
      () {
        expect(
          DeepLinkResolver.resolveLocation(const {'type': 'quran_session'}),
          QuranSessionsRoutes.mySessions,
        );
      },
    );
  });

  group('DeepLinkResolver.resolveExtra', () {
    test('returns embedded reciter entity for reciter routes', () {
      final String location = const ReciterDetailsRoute(
        reciterId: '9',
      ).location;
      final Object? extra = DeepLinkResolver.resolveExtra(
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

    test('returns raw payload string for prayer status route', () {
      final String location = const PrayerNotificationStatusRoute().location;
      final Object? extra = DeepLinkResolver.resolveExtra(
        const {'payload': 'adhan-json'},
        location,
      );
      expect(extra, 'adhan-json');
    });
  });

  group('DeepLinkResolver typed factories', () {
    test(
      'athkarMorning targets category 1 and is attributed to notification',
      () {
        final NotificationDestination dest = resolver.athkarMorning();
        expect(Uri.parse(dest.location).path, '/athkar/1');
        expect(dest.source, NavigationSource.notification);
        expect(
          Uri.parse(dest.location).queryParameters['source'],
          NavigationSource.notification.wireValue,
        );
      },
    );

    test('athkarEvening targets category 2', () {
      final NotificationDestination dest = resolver.athkarEvening();
      expect(Uri.parse(dest.location).path, '/athkar/2');
      expect(dest.source, NavigationSource.notification);
    });

    test('prayerStatus carries the raw payload as extra', () {
      final NotificationDestination dest = resolver.prayerStatus('payload-123');
      expect(dest.location, const PrayerNotificationStatusRoute().location);
      expect(dest.extra, 'payload-123');
      expect(dest.source, NavigationSource.notification);
    });
  });

  group('DeepLinkResolver.notificationDataFromPayload', () {
    test('resolves morning athkar string payload to category 1', () {
      final Map<String, dynamic>? data =
          DeepLinkResolver.notificationDataFromPayload(
            'morning_athkar_20260605',
          );
      expect(data, isNotNull);
      expect(
        DeepLinkResolver.resolveLocation(data!),
        startsWith('/athkar/1'),
      );
    });

    test('resolves evening athkar string payload to category 2', () {
      final Map<String, dynamic>? data =
          DeepLinkResolver.notificationDataFromPayload(
            'evening_athkar_20260605',
          );
      expect(data, isNotNull);
      expect(
        DeepLinkResolver.resolveLocation(data!),
        startsWith('/athkar/2'),
      );
    });

    test('still decodes JSON payloads', () {
      expect(
        DeepLinkResolver.notificationDataFromPayload('{"type":"settings"}'),
        const {'type': 'settings'},
      );
    });

    test('resolves tasbeeh reminder string payload to tasbeeh data', () {
      final Map<String, dynamic>? data =
          DeepLinkResolver.notificationDataFromPayload(
            '${TasbeehConstants.reminderPayloadPrefix}abc',
          );

      expect(data, const {'type': 'tasbeeh', 'dhikrId': 'abc'});
      expect(
        DeepLinkResolver.resolveLocation(data!),
        const TasbeehRoute(dhikrId: 'abc').location,
      );
    });

    test('returns null for null, empty, or non-athkar non-JSON payloads', () {
      expect(DeepLinkResolver.notificationDataFromPayload(null), isNull);
      expect(DeepLinkResolver.notificationDataFromPayload(''), isNull);
      expect(DeepLinkResolver.notificationDataFromPayload('not-json'), isNull);
      expect(
        DeepLinkResolver.notificationDataFromPayload(
          TasbeehConstants.reminderPayloadPrefix,
        ),
        isNull,
      );
    });
  });

  group('resolveFromData', () {
    test('builds a destination with resolved location, extra and source', () {
      final NotificationDestination dest = resolver.resolveFromData(
        const {'type': 'reciter', 'reciterId': '7'},
      );
      expect(dest.location, const ReciterDetailsRoute(reciterId: '7').location);
      expect(dest.source, NavigationSource.notification);
    });
  });
}
