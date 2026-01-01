import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/constants/analytics_constants.dart';
import 'package:tilawa/core/services/firebase_analytics_service.dart';

import 'analytics_service_test.mocks.dart';

@GenerateMocks([FirebaseAnalytics])
void main() {
  late FirebaseAnalyticsService service;
  late MockFirebaseAnalytics mockAnalytics;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    service = FirebaseAnalyticsService(mockAnalytics);
    service.testMode = true;
  });

  group('FirebaseAnalyticsService', () {
    test('Constructor disables collection when debugMode is true', () async {
      final mock = MockFirebaseAnalytics();
      FirebaseAnalyticsService(mock);
      verify(mock.setAnalyticsCollectionEnabled(false)).called(1);
    });

    test('logEvent returns early when debugMode is true', () async {
      final mock = MockFirebaseAnalytics();
      final debugService = FirebaseAnalyticsService(mock);
      await debugService.logEvent('test');
      verifyNever(
        mock.logEvent(
          name: anyNamed('name'),
          parameters: anyNamed('parameters'),
        ),
      );
    });

    test('setUserId returns early when debugMode is true', () async {
      final mock = MockFirebaseAnalytics();
      final debugService = FirebaseAnalyticsService(mock);
      await debugService.setUserId('u1');
      verifyNever(mock.setUserId(id: anyNamed('id')));
    });

    test('setUserProperty returns early when debugMode is true', () async {
      final mock = MockFirebaseAnalytics();
      final debugService = FirebaseAnalyticsService(mock);
      await debugService.setUserProperty('p1', 'v1');
      verifyNever(
        mock.setUserProperty(name: anyNamed('name'), value: anyNamed('value')),
      );
    });

    test('resetAnalyticsData returns early when debugMode is true', () async {
      final mock = MockFirebaseAnalytics();
      final debugService = FirebaseAnalyticsService(mock);
      await debugService.resetAnalyticsData();
      verifyNever(mock.resetAnalyticsData());
    });

    test('logEvent calls underlying SDK when debugMode is false', () async {
      final params = {'key': 'value'};
      await service.logEvent('test_event', parameters: params);
      verify(
        mockAnalytics.logEvent(name: 'test_event', parameters: params),
      ).called(1);
    });

    test('logEvent handles errors gracefully', () async {
      when(
        mockAnalytics.logEvent(
          name: anyNamed('name'),
          parameters: anyNamed('parameters'),
        ),
      ).thenThrow(Exception('Firebase error'));

      await expectLater(service.logEvent('test'), completes);
    });

    test('logLogin calls logEvent with correct parameters', () async {
      await service.logLogin(loginMethod: 'google');
      verify(
        mockAnalytics.logEvent(
          name: AnalyticsEvents.login,
          parameters: {AnalyticsParams.method: 'google'},
        ),
      ).called(1);
    });

    test('logSignUp calls logEvent with correct parameters', () async {
      await service.logSignUp(signUpMethod: 'email');
      verify(
        mockAnalytics.logEvent(
          name: AnalyticsEvents.signUp,
          parameters: {AnalyticsParams.method: 'email'},
        ),
      ).called(1);
    });

    test('logScreenView calls logEvent with correct parameters', () async {
      await service.logScreenView('Home', screenClass: 'HomeScreen');
      verify(
        mockAnalytics.logEvent(
          name: AnalyticsEvents.screenView,
          parameters: {
            AnalyticsParams.screenName: 'Home',
            AnalyticsParams.screenClass: 'HomeScreen',
          },
        ),
      ).called(1);
    });

    test('logAudioPlay cleans parameters and calls SDK', () async {
      await service.logAudioPlay('1', audioName: 'Surah');
      verify(
        mockAnalytics.logEvent(
          name: AnalyticsEvents.audioPlay,
          parameters: {
            AnalyticsParams.audioId: '1',
            AnalyticsParams.audioName: 'Surah',
          },
        ),
      ).called(1);
    });

    test('logAudioPause calls SDK', () async {
      await service.logAudioPause('1');
      verify(
        mockAnalytics.logEvent(
          name: AnalyticsEvents.audioPause,
          parameters: {AnalyticsParams.audioId: '1'},
        ),
      ).called(1);
    });

    test('logAudioStop calls SDK', () async {
      await service.logAudioStop('1');
      verify(
        mockAnalytics.logEvent(
          name: AnalyticsEvents.audioStop,
          parameters: {AnalyticsParams.audioId: '1'},
        ),
      ).called(1);
    });

    test('logAudioSeek calls SDK', () async {
      await service.logAudioSeek('1', 100);
      verify(
        mockAnalytics.logEvent(
          name: AnalyticsEvents.audioSeek,
          parameters: {
            AnalyticsParams.audioId: '1',
            AnalyticsParams.position: 100,
          },
        ),
      ).called(1);
    });

    test('logDownloadStart calls SDK with clean parameters', () async {
      await service.logDownloadStart('d1', fileName: 'file');
      verify(
        mockAnalytics.logEvent(
          name: AnalyticsEvents.downloadStart,
          parameters: {
            AnalyticsParams.downloadId: 'd1',
            AnalyticsParams.fileName: 'file',
          },
        ),
      ).called(1);
    });

    test('logDownloadComplete calls SDK', () async {
      await service.logDownloadComplete('d1', fileName: 'file', fileSize: 1024);
      verify(
        mockAnalytics.logEvent(
          name: AnalyticsEvents.downloadComplete,
          parameters: {
            AnalyticsParams.downloadId: 'd1',
            AnalyticsParams.fileName: 'file',
            AnalyticsParams.fileSize: 1024,
          },
        ),
      ).called(1);
    });

    test('logDownloadCancel calls SDK', () async {
      await service.logDownloadCancel('d1', fileName: 'file');
      verify(
        mockAnalytics.logEvent(
          name: AnalyticsEvents.downloadCancel,
          parameters: {
            AnalyticsParams.downloadId: 'd1',
            AnalyticsParams.fileName: 'file',
          },
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
        mockAnalytics.logEvent(
          name: AnalyticsEvents.purchase,
          parameters: {
            AnalyticsParams.transactionId: 't1',
            AnalyticsParams.value: 9.99,
            AnalyticsParams.currency: 'USD',
            AnalyticsParams.itemId: 'i1',
          },
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
        mockAnalytics.logEvent(
          name: AnalyticsEvents.subscriptionStart,
          parameters: {
            AnalyticsParams.subscriptionId: 's1',
            AnalyticsParams.planId: 'monthly',
            AnalyticsParams.value: 4.99,
            AnalyticsParams.currency: 'USD',
          },
        ),
      ).called(1);
    });

    test('logSubscriptionCancel calls SDK', () async {
      await service.logSubscriptionCancel('s1', planId: 'monthly');
      verify(
        mockAnalytics.logEvent(
          name: AnalyticsEvents.subscriptionCancel,
          parameters: {
            AnalyticsParams.subscriptionId: 's1',
            AnalyticsParams.planId: 'monthly',
          },
        ),
      ).called(1);
    });

    test('logSearch calls SDK', () async {
      await service.logSearch('test', resultCount: 5);
      verify(
        mockAnalytics.logEvent(
          name: AnalyticsEvents.search,
          parameters: {
            AnalyticsParams.searchTerm: 'test',
            AnalyticsParams.resultCount: 5,
          },
        ),
      ).called(1);
    });

    test('logShare calls SDK', () async {
      await service.logShare('audio', itemId: '1');
      verify(
        mockAnalytics.logEvent(
          name: AnalyticsEvents.share,
          parameters: {
            AnalyticsParams.contentType: 'audio',
            AnalyticsParams.itemId: '1',
          },
        ),
      ).called(1);
    });

    test('logFavorite calls SDK', () async {
      await service.logFavorite('1', itemType: 'audio');
      verify(
        mockAnalytics.logEvent(
          name: AnalyticsEvents.favorite,
          parameters: {
            AnalyticsParams.itemId: '1',
            AnalyticsParams.itemType: 'audio',
          },
        ),
      ).called(1);
    });

    test('logRating calls SDK', () async {
      await service.logRating(5, itemId: '1', itemType: 'audio');
      verify(
        mockAnalytics.logEvent(
          name: AnalyticsEvents.rating,
          parameters: {
            AnalyticsParams.ratingValue: 5,
            AnalyticsParams.itemId: '1',
            AnalyticsParams.itemType: 'audio',
          },
        ),
      ).called(1);
    });

    test('setUserId calls SDK and handles error', () async {
      await service.setUserId('u1');
      verify(mockAnalytics.setUserId(id: 'u1')).called(1);

      when(
        mockAnalytics.setUserId(id: anyNamed('id')),
      ).thenThrow(Exception('error'));
      await expectLater(service.setUserId('u2'), completes);
    });

    test('setUserProperty calls SDK and handles error', () async {
      await service.setUserProperty('p1', 'v1');
      verify(mockAnalytics.setUserProperty(name: 'p1', value: 'v1')).called(1);

      when(
        mockAnalytics.setUserProperty(
          name: anyNamed('name'),
          value: anyNamed('value'),
        ),
      ).thenThrow(Exception('error'));
      await expectLater(service.setUserProperty('p2', 'v2'), completes);
    });

    test('resetAnalyticsData calls SDK and handles error', () async {
      await service.resetAnalyticsData();
      verify(mockAnalytics.resetAnalyticsData()).called(1);

      when(mockAnalytics.resetAnalyticsData()).thenThrow(Exception('error'));
      await expectLater(service.resetAnalyticsData(), completes);
    });
  });
}
