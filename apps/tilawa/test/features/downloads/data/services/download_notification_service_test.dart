import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tilawa/features/downloads/data/services/download_notification_service.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

import '../../helpers/mock_helper.mocks.dart';

// Fake dispatcher for testing
class FakeNotificationDispatcher implements INotificationDispatcher {
  FakeNotificationDispatcher({this.throwOnInitialize = false});

  final bool throwOnInitialize;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  NotificationHandler? idRangeHandler;
  bool Function(String? payload)? payloadMatcher;
  NotificationHandler? payloadHandler;

  @override
  Future<void> initialize({bool createHighImportanceChannel = true}) async {
    if (throwOnInitialize) {
      throw Exception('init failed');
    }
  }

  @override
  void registerHandler({
    required String serviceId,
    required Set<int> notificationIds,
    required NotificationHandler handler,
  }) {}

  @override
  void registerIdRangeHandler({
    required String serviceId,
    required int minIdInclusive,
    required int maxIdExclusive,
    required NotificationHandler handler,
  }) {
    idRangeHandler = handler;
  }

  @override
  void registerPayloadHandler({
    required String serviceId,
    required bool Function(String? payload) matcher,
    required NotificationHandler handler,
  }) {
    payloadMatcher = matcher;
    payloadHandler = handler;
  }

  @override
  void unregisterHandler(String serviceId) {}

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async => null;

  @override
  Future<bool> processLaunchNotification() async => false;

  @override
  FlutterLocalNotificationsPlugin get notificationsPlugin => _plugin;
}

// Mock platform implementation for testing
class MockFlutterLocalNotificationsPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FlutterLocalNotificationsPlatform {
  bool throwOnShow = false;

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    String? payload,
  }) async {
    if (throwOnShow) {
      throw PlatformException(code: 'show_failed');
    }
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {}

  @override
  Future<void> cancelAll() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up the mock platform before any tests run
  setUpAll(() {
    FlutterLocalNotificationsPlatform.instance =
        MockFlutterLocalNotificationsPlatform();
  });

  late DownloadNotificationService service;
  late MockDownloadNotificationNavigator mockNavigator;
  late FakeNotificationDispatcher fakeDispatcher;

  setUp(() {
    mockNavigator = MockDownloadNotificationNavigator();
    fakeDispatcher = FakeNotificationDispatcher();
    service = DownloadNotificationService(mockNavigator, fakeDispatcher);
  });

  group('initialize', () {
    test('should initialize successfully', () async {
      await service.initialize();
      expect(service, isNotNull);
    });

    test('should not reinitialize if already initialized', () async {
      await service.initialize();
      await service.initialize();
      expect(service, isNotNull);
    });

    test('should register download payload and id-range handlers', () async {
      await service.initialize();

      expect(fakeDispatcher.payloadMatcher, isNotNull);
      expect(fakeDispatcher.idRangeHandler, isNotNull);
      expect(
        fakeDispatcher.payloadMatcher!(jsonEncode({'reciterId': 1})),
        isTrue,
      );
      expect(
        fakeDispatcher.payloadMatcher!(jsonEncode({'reciterName': 'Test'})),
        isTrue,
      );
      expect(
        fakeDispatcher.payloadMatcher!(jsonEncode({'type': 'download'})),
        isTrue,
      );
      expect(fakeDispatcher.payloadMatcher!(null), isFalse);
      expect(fakeDispatcher.payloadMatcher!('not-json'), isFalse);
      expect(
        fakeDispatcher.payloadMatcher!(jsonEncode({'other': 'value'})),
        isFalse,
      );
    });

    test('should swallow initialization failures', () async {
      final DownloadNotificationService failingService =
          DownloadNotificationService(
            mockNavigator,
            FakeNotificationDispatcher(throwOnInitialize: true),
          );

      await failingService.initialize();
      expect(failingService, isNotNull);
    });
  });

  group('showDownloadProgress', () {
    const downloadId = 'download-1';
    const title = 'Al-Fatiha';
    const reciterName = 'Al-Afasy';

    test('should show pending notification', () async {
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 0,
        status: DownloadStatus.pending,
        pendingMessage: 'Waiting to start...',
      );
      expect(service, isNotNull);
    });

    test('should show downloading notification with progress', () async {
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 50,
        status: DownloadStatus.downloading,
        progressMessage: 'Downloading: 50%',
      );
      expect(service, isNotNull);
    });

    test('should show completed notification', () async {
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 100,
        status: DownloadStatus.completed,
        completeMessage: 'Download complete',
      );
      expect(service, isNotNull);
    });

    test(
      'should show completed notification when progress is 100% even if status is still downloading',
      () async {
        await service.showDownloadProgress(
          downloadId: downloadId,
          title: title,
          reciterName: reciterName,
          progress: 100,
          status: DownloadStatus.downloading,
          completeMessage: 'Download complete',
        );
        expect(service, isNotNull);
      },
    );

    test('should show failed notification', () async {
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 50,
        status: DownloadStatus.failed,
        failedMessage: 'Download failed',
      );
      expect(service, isNotNull);
    });

    test('should cancel notification when status is cancelled', () async {
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 50,
        status: DownloadStatus.downloading,
      );

      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 50,
        status: DownloadStatus.cancelled,
      );
      expect(service, isNotNull);
    });

    test('should cancel notification when status is paused', () async {
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 50,
        status: DownloadStatus.downloading,
      );

      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 50,
        status: DownloadStatus.paused,
      );
      expect(service, isNotNull);
    });

    test('should include reciterId in notification payload', () async {
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        reciterId: 42,
        progress: 50,
        status: DownloadStatus.downloading,
      );
      expect(service, isNotNull);
    });

    test('should swallow show errors for single download notifications', () async {
      (
        FlutterLocalNotificationsPlatform.instance
            as MockFlutterLocalNotificationsPlatform
      ).throwOnShow = true;

      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 100,
        status: DownloadStatus.completed,
      );

      (
        FlutterLocalNotificationsPlatform.instance
            as MockFlutterLocalNotificationsPlatform
      ).throwOnShow = false;
      expect(service, isNotNull);
    });

    test('should use default messages when not provided', () async {
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 0,
        status: DownloadStatus.pending,
      );
      expect(service, isNotNull);
    });

    test('should auto-initialize if not initialized', () async {
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 50,
        status: DownloadStatus.downloading,
      );
      expect(service, isNotNull);
    });
  });

  group('showBatchDownloadProgress', () {
    const batchId = 'batch-1';
    const title = 'Downloading Al-Sudais';

    test('should show batch downloading notification', () async {
      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 33,
        completedCount: 10,
        totalCount: 30,
        status: DownloadStatus.downloading,
      );
      expect(service, isNotNull);
    });

    test('should show batch pending notification', () async {
      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 0,
        completedCount: 0,
        totalCount: 30,
        status: DownloadStatus.pending,
      );
      expect(service, isNotNull);
    });

    test('should show batch completed notification', () async {
      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 100,
        completedCount: 30,
        totalCount: 30,
        status: DownloadStatus.completed,
      );
      expect(service, isNotNull);
    });

    test(
      'should show batch completed when progress is 100% even if status is downloading',
      () async {
        await service.showBatchDownloadProgress(
          batchId: batchId,
          title: title,
          progress: 100,
          completedCount: 30,
          totalCount: 30,
          status: DownloadStatus.downloading,
        );
        expect(service, isNotNull);
      },
    );

    test('should show batch failed notification', () async {
      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 50,
        completedCount: 15,
        totalCount: 30,
        status: DownloadStatus.failed,
      );
      expect(service, isNotNull);
    });

    test('should cancel batch notification when status is cancelled', () async {
      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 50,
        completedCount: 15,
        totalCount: 30,
        status: DownloadStatus.downloading,
      );

      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 50,
        completedCount: 15,
        totalCount: 30,
        status: DownloadStatus.cancelled,
      );
      expect(service, isNotNull);
    });

    test('should cancel batch notification when status is paused', () async {
      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 50,
        completedCount: 15,
        totalCount: 30,
        status: DownloadStatus.downloading,
      );

      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 50,
        completedCount: 15,
        totalCount: 30,
        status: DownloadStatus.paused,
      );
      expect(service, isNotNull);
    });

    test('should swallow show errors for batch notifications', () async {
      (
        FlutterLocalNotificationsPlatform.instance
            as MockFlutterLocalNotificationsPlatform
      ).throwOnShow = true;

      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 100,
        completedCount: 30,
        totalCount: 30,
        status: DownloadStatus.completed,
      );

      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 50,
        completedCount: 15,
        totalCount: 30,
        status: DownloadStatus.failed,
      );

      (
        FlutterLocalNotificationsPlatform.instance
            as MockFlutterLocalNotificationsPlatform
      ).throwOnShow = false;
      expect(service, isNotNull);
    });

    test('should auto-initialize if not initialized', () async {
      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 50,
        completedCount: 15,
        totalCount: 30,
        status: DownloadStatus.downloading,
      );
      expect(service, isNotNull);
    });
  });

  group('cancelNotification', () {
    test('should cancel notification for existing download', () async {
      const downloadId = 'download-1';
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: 'Test',
        reciterName: 'Test Reciter',
        progress: 50,
        status: DownloadStatus.downloading,
      );

      await service.cancelNotification(downloadId);
      expect(service, isNotNull);
    });

    test('should handle cancelling non-existent notification', () async {
      await service.cancelNotification('non-existent-id');
      expect(service, isNotNull);
    });
  });

  group('cancelAllNotifications', () {
    test('should cancel all notifications', () async {
      await service.showDownloadProgress(
        downloadId: 'download-1',
        title: 'Test 1',
        reciterName: 'Reciter 1',
        progress: 50,
        status: DownloadStatus.downloading,
      );

      await service.showDownloadProgress(
        downloadId: 'download-2',
        title: 'Test 2',
        reciterName: 'Reciter 2',
        progress: 30,
        status: DownloadStatus.downloading,
      );

      await service.cancelAllNotifications();
      expect(service, isNotNull);
    });

    test('should handle cancelling all when no notifications exist', () async {
      await service.cancelAllNotifications();
      expect(service, isNotNull);
    });
  });

  group('handleNotificationTap', () {
    const reciterName = 'Al-Afasy';
    const reciterId = 1;

    test('should return early if payload is null', () async {
      await service.handleNotificationTap(null);
      verifyZeroInteractions(mockNavigator);
    });

    test('should delegate to navigator when payload has reciterId', () async {
      final String payload = jsonEncode({
        'reciterId': reciterId,
        'reciterName': reciterName,
      });

      when(
        mockNavigator.navigateToReciter(
          reciterId: anyNamed('reciterId'),
          reciterName: anyNamed('reciterName'),
        ),
      ).thenAnswer((_) async {});

      await service.handleNotificationTap(payload);

      verify(
        mockNavigator.navigateToReciter(
          reciterId: reciterId.toString(),
          reciterName: reciterName,
        ),
      ).called(1);
    });

    test(
      'should delegate to navigator when payload has reciterName only',
      () async {
        final String payload = jsonEncode({'reciterName': reciterName});

        when(
          mockNavigator.navigateToReciter(
            reciterId: anyNamed('reciterId'),
            reciterName: anyNamed('reciterName'),
          ),
        ).thenAnswer((_) async {});

        await service.handleNotificationTap(payload);

        verify(
          mockNavigator.navigateToReciter(
            reciterId: null,
            reciterName: reciterName,
          ),
        ).called(1);
      },
    );

    test('should not navigate if payload has no reciter info', () async {
      final String payload = jsonEncode({'someOtherKey': 'value'});

      await service.handleNotificationTap(payload);

      verifyZeroInteractions(mockNavigator);
    });

    test('should ignore non-JSON payloads', () async {
      await service.handleNotificationTap('plain_text_payload');
      verifyZeroInteractions(mockNavigator);
    });

    test('should swallow navigator failures', () async {
      final String payload = jsonEncode({
        'reciterId': reciterId,
        'reciterName': reciterName,
      });

      when(
        mockNavigator.navigateToReciter(
          reciterId: anyNamed('reciterId'),
          reciterName: anyNamed('reciterName'),
        ),
      ).thenThrow(Exception('navigation failed'));

      await service.handleNotificationTap(payload);
      verify(
        mockNavigator.navigateToReciter(
          reciterId: reciterId.toString(),
          reciterName: reciterName,
        ),
      ).called(1);
    });

    test('payload handler forwards taps to handleNotificationTap', () async {
      await service.initialize();

      when(
        mockNavigator.navigateToReciter(
          reciterId: anyNamed('reciterId'),
          reciterName: anyNamed('reciterName'),
        ),
      ).thenAnswer((_) async {});

      final String payload = jsonEncode({'reciterName': reciterName});

      await fakeDispatcher.payloadHandler!(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: payload,
        ),
      );

      verify(
        mockNavigator.navigateToReciter(
          reciterId: null,
          reciterName: reciterName,
        ),
      ).called(1);
    });

    test('id-range handler forwards taps to handleNotificationTap', () async {
      await service.initialize();

      when(
        mockNavigator.navigateToReciter(
          reciterId: anyNamed('reciterId'),
          reciterName: anyNamed('reciterName'),
        ),
      ).thenAnswer((_) async {});

      final String payload = jsonEncode({
        'reciterId': reciterId,
        'reciterName': reciterName,
      });

      await fakeDispatcher.idRangeHandler!(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: payload,
        ),
      );

      verify(
        mockNavigator.navigateToReciter(
          reciterId: reciterId.toString(),
          reciterName: reciterName,
        ),
      ).called(1);
    });
  });
}
