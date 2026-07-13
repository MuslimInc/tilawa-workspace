import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/services/firebase_analytics_service.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

/// Verifies Firebase [parameters] include [expected] and [client_timestamp_ms].
Matcher analyticsParams(Map<String, Object> expected) =>
    predicate<Map<String, Object>>(
      (Map<String, Object> actual) =>
          actual[AnalyticsParams.clientTimestampMs] is int &&
          expected.entries.every((e) => actual[e.key] == e.value),
      'parameters with client_timestamp_ms and $expected',
    );

void main() {
  late FirebaseAnalyticsService service;
  late MockFirebaseAnalytics mockAnalytics;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    when(
      () => mockAnalytics.setAnalyticsCollectionEnabled(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockAnalytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    service = FirebaseAnalyticsService(mockAnalytics);
    service.testMode = true;
  });

  group('FirebaseAnalyticsService', () {
    test('Constructor disables collection when debugMode is true', () async {
      final mock = MockFirebaseAnalytics();
      when(
        () => mock.setAnalyticsCollectionEnabled(false),
      ).thenAnswer((_) async {});
      FirebaseAnalyticsService(mock);
      verify(() => mock.setAnalyticsCollectionEnabled(false)).called(1);
    });

    test('logEvent returns early when debugMode is true', () async {
      final mock = MockFirebaseAnalytics();
      when(
        () => mock.setAnalyticsCollectionEnabled(any()),
      ).thenAnswer((_) async {});
      final debugService = FirebaseAnalyticsService(mock);
      await debugService.logEvent('test');
      verifyNever(
        () => mock.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      );
    });

    test('setUserId returns early when debugMode is true', () async {
      final mock = MockFirebaseAnalytics();
      when(
        () => mock.setAnalyticsCollectionEnabled(any()),
      ).thenAnswer((_) async {});
      final debugService = FirebaseAnalyticsService(mock);
      await debugService.setUserId('u1');
      verifyNever(() => mock.setUserId(id: any(named: 'id')));
    });

    test('setUserProperty returns early when debugMode is true', () async {
      final mock = MockFirebaseAnalytics();
      when(
        () => mock.setAnalyticsCollectionEnabled(any()),
      ).thenAnswer((_) async {});
      final debugService = FirebaseAnalyticsService(mock);
      await debugService.setUserProperty('p1', 'v1');
      verifyNever(
        () => mock.setUserProperty(
          name: any(named: 'name'),
          value: any(named: 'value'),
        ),
      );
    });

    test('resetAnalyticsData returns early when debugMode is true', () async {
      final mock = MockFirebaseAnalytics();
      when(
        () => mock.setAnalyticsCollectionEnabled(any()),
      ).thenAnswer((_) async {});
      final debugService = FirebaseAnalyticsService(mock);
      await debugService.resetAnalyticsData();
      verifyNever(mock.resetAnalyticsData);
    });

    test('logEvent calls underlying SDK when debugMode is false', () async {
      await service.logEvent('test_event', parameters: {'key': 'value'});
      verify(
        () => mockAnalytics.logEvent(
          name: 'test_event',
          parameters: any(
            named: 'parameters',
            that: analyticsParams({'key': 'value'}),
          ),
        ),
      ).called(1);
    });

    test('logEvent handles errors gracefully', () async {
      when(
        () => mockAnalytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenThrow(Exception('Firebase error'));

      await expectLater(service.logEvent('test'), completes);
    });

    test('logLogin calls logEvent with correct parameters', () async {
      await service.logLogin(loginMethod: 'google');
      verify(
        () => mockAnalytics.logEvent(
          name: AnalyticsEvents.login,
          parameters: any(
            named: 'parameters',
            that: analyticsParams({AnalyticsParams.method: 'google'}),
          ),
        ),
      ).called(1);
    });

    test('logSignUp calls logEvent with correct parameters', () async {
      await service.logSignUp(signUpMethod: 'email');
      verify(
        () => mockAnalytics.logEvent(
          name: AnalyticsEvents.signUp,
          parameters: any(
            named: 'parameters',
            that: analyticsParams({AnalyticsParams.method: 'email'}),
          ),
        ),
      ).called(1);
    });

    test('logScreenView calls logEvent with correct parameters', () async {
      await service.logScreenView('Home', screenClass: 'HomeScreen');
      verify(
        () => mockAnalytics.logEvent(
          name: AnalyticsEvents.screenView,
          parameters: any(
            named: 'parameters',
            that: analyticsParams({
              AnalyticsParams.screenName: 'Home',
              AnalyticsParams.screenClass: 'HomeScreen',
            }),
          ),
        ),
      ).called(1);
    });

    test('logAudioPlay cleans parameters and calls SDK', () async {
      await service.logAudioPlay('1', audioName: 'Surah');
      verify(
        () => mockAnalytics.logEvent(
          name: AnalyticsEvents.audioPlay,
          parameters: any(
            named: 'parameters',
            that: analyticsParams({
              AnalyticsParams.audioId: '1',
              AnalyticsParams.audioName: 'Surah',
            }),
          ),
        ),
      ).called(1);
    });

    test('logAudioPause calls SDK', () async {
      await service.logAudioPause('1');
      verify(
        () => mockAnalytics.logEvent(
          name: AnalyticsEvents.audioPause,
          parameters: any(
            named: 'parameters',
            that: analyticsParams({AnalyticsParams.audioId: '1'}),
          ),
        ),
      ).called(1);
    });

    test('logAudioStop calls SDK', () async {
      await service.logAudioStop('1');
      verify(
        () => mockAnalytics.logEvent(
          name: AnalyticsEvents.audioStop,
          parameters: any(
            named: 'parameters',
            that: analyticsParams({AnalyticsParams.audioId: '1'}),
          ),
        ),
      ).called(1);
    });

    test('logAudioSeek calls SDK', () async {
      await service.logAudioSeek('1', 100);
      verify(
        () => mockAnalytics.logEvent(
          name: AnalyticsEvents.audioSeek,
          parameters: any(
            named: 'parameters',
            that: analyticsParams({
              AnalyticsParams.audioId: '1',
              AnalyticsParams.position: 100,
            }),
          ),
        ),
      ).called(1);
    });

    test('logPurchase calls SDK', () async {
      await service.logPurchase(
        't1',
        value: 9.99,
        currency: 'USD',
        itemId: 'i1',
      );
      verify(
        () => mockAnalytics.logEvent(
          name: AnalyticsEvents.purchase,
          parameters: any(
            named: 'parameters',
            that: analyticsParams({
              AnalyticsParams.transactionId: 't1',
              AnalyticsParams.value: 9.99,
              AnalyticsParams.currency: 'USD',
              AnalyticsParams.itemId: 'i1',
            }),
          ),
        ),
      ).called(1);
    });

    test('logSubscriptionStart calls SDK', () async {
      await service.logSubscriptionStart(
        's1',
        planId: 'monthly',
        value: 4.99,
        currency: 'USD',
      );
      verify(
        () => mockAnalytics.logEvent(
          name: AnalyticsEvents.subscriptionStart,
          parameters: any(
            named: 'parameters',
            that: analyticsParams({
              AnalyticsParams.subscriptionId: 's1',
              AnalyticsParams.planId: 'monthly',
              AnalyticsParams.value: 4.99,
              AnalyticsParams.currency: 'USD',
            }),
          ),
        ),
      ).called(1);
    });

    test('logSubscriptionCancel calls SDK', () async {
      await service.logSubscriptionCancel('s1', planId: 'monthly');
      verify(
        () => mockAnalytics.logEvent(
          name: AnalyticsEvents.subscriptionCancel,
          parameters: any(
            named: 'parameters',
            that: analyticsParams({
              AnalyticsParams.subscriptionId: 's1',
              AnalyticsParams.planId: 'monthly',
            }),
          ),
        ),
      ).called(1);
    });

    test('logSearch calls SDK', () async {
      await service.logSearch('test', resultCount: 5);
      verify(
        () => mockAnalytics.logEvent(
          name: AnalyticsEvents.search,
          parameters: any(
            named: 'parameters',
            that: analyticsParams({
              AnalyticsParams.searchTerm: 'test',
              AnalyticsParams.resultCount: 5,
            }),
          ),
        ),
      ).called(1);
    });

    test('logShare calls SDK', () async {
      await service.logShare('audio', itemId: '1');
      verify(
        () => mockAnalytics.logEvent(
          name: AnalyticsEvents.share,
          parameters: any(
            named: 'parameters',
            that: analyticsParams({
              AnalyticsParams.contentType: 'audio',
              AnalyticsParams.itemId: '1',
            }),
          ),
        ),
      ).called(1);
    });

    test('logFavorite calls SDK', () async {
      await service.logFavorite('1', itemType: 'audio');
      verify(
        () => mockAnalytics.logEvent(
          name: AnalyticsEvents.favorite,
          parameters: any(
            named: 'parameters',
            that: analyticsParams({
              AnalyticsParams.itemId: '1',
              AnalyticsParams.itemType: 'audio',
            }),
          ),
        ),
      ).called(1);
    });

    test('logRating calls SDK', () async {
      await service.logRating(5, itemId: '1', itemType: 'audio');
      verify(
        () => mockAnalytics.logEvent(
          name: AnalyticsEvents.rating,
          parameters: any(
            named: 'parameters',
            that: analyticsParams({
              AnalyticsParams.ratingValue: 5,
              AnalyticsParams.itemId: '1',
              AnalyticsParams.itemType: 'audio',
            }),
          ),
        ),
      ).called(1);
    });

    test('setUserId calls SDK and handles error', () async {
      when(() => mockAnalytics.setUserId(id: 'u1')).thenAnswer((_) async {});
      await service.setUserId('u1');
      verify(() => mockAnalytics.setUserId(id: 'u1')).called(1);

      when(
        () => mockAnalytics.setUserId(id: any(named: 'id')),
      ).thenThrow(Exception('error'));
      await expectLater(service.setUserId('u2'), completes);
    });

    test('setUserProperty calls SDK and handles error', () async {
      when(
        () => mockAnalytics.setUserProperty(name: 'p1', value: 'v1'),
      ).thenAnswer((_) async {});
      await service.setUserProperty('p1', 'v1');
      verify(
        () => mockAnalytics.setUserProperty(name: 'p1', value: 'v1'),
      ).called(1);

      when(
        () => mockAnalytics.setUserProperty(
          name: any(named: 'name'),
          value: any(named: 'value'),
        ),
      ).thenThrow(Exception('error'));
      await expectLater(service.setUserProperty('p2', 'v2'), completes);
    });

    test('resetAnalyticsData calls SDK and handles error', () async {
      when(() => mockAnalytics.resetAnalyticsData()).thenAnswer((_) async {});
      await service.resetAnalyticsData();
      verify(() => mockAnalytics.resetAnalyticsData()).called(1);

      when(
        () => mockAnalytics.resetAnalyticsData(),
      ).thenThrow(Exception('error'));
      await expectLater(service.resetAnalyticsData(), completes);
    });
  });
}
