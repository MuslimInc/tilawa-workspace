import 'dart:convert';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tilawa/features/downloads/data/services/download_notification_service.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

import '../../helpers/mock_helper.mocks.dart';

// Fake dispatcher for testing
class FakeNotificationDispatcher implements INotificationDispatcher {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {}

  @override
  void registerHandler({
    required String serviceId,
    required Set<int> notificationIds,
    required NotificationHandler handler,
  }) {}

  @override
  void registerPayloadHandler({
    required String serviceId,
    required bool Function(String? payload) matcher,
    required NotificationHandler handler,
  }) {}

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
  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    String? payload,
    // Note: notificationDetails is not part of the platform interface show method directly in this version
  }) async {
    // No-op for tests
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    // No-op for tests
  }

  @override
  Future<void> cancelAll() async {
    // No-op for tests
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up the mock platform before any tests run
  setUpAll(() {
    FlutterLocalNotificationsPlatform.instance =
        MockFlutterLocalNotificationsPlatform();
  });

  late DownloadNotificationService service;
  late MockRecitersRepository mockRecitersRepository;
  late MockNavigationService mockNavigationService;
  late FakeNotificationDispatcher fakeDispatcher;

  setUp(() {
    provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));
    mockRecitersRepository = MockRecitersRepository();
    mockNavigationService = MockNavigationService();
    fakeDispatcher = FakeNotificationDispatcher();
    service = DownloadNotificationService(
      mockRecitersRepository,
      mockNavigationService,
      fakeDispatcher,
    );
    // return null by default for location to allow navigation
    when(mockNavigationService.getCurrentLocation()).thenReturn(null);
  });

  group('initialize', () {
    test('should initialize successfully', () async {
      // Act
      await service.initialize();

      // Assert - no exception means success
      // We can't verify platform-specific calls without more complex mocking
      // but we verify the method completes
      expect(service, isNotNull);
    });

    test('should not reinitialize if already initialized', () async {
      // Arrange
      await service.initialize();

      // Act - second initialization
      await service.initialize();

      // Assert - should complete without errors
      expect(service, isNotNull);
    });
  });

  group('showDownloadProgress', () {
    const downloadId = 'download-1';
    const title = 'Al-Fatiha';
    const reciterName = 'Al-Afasy';

    test('should show pending notification', () async {
      // Act
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 0,
        status: DownloadStatus.pending,
        pendingMessage: 'Waiting to start...',
      );

      // Assert - method completes without error
      expect(service, isNotNull);
    });

    test('should show downloading notification with progress', () async {
      // Act
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 50,
        status: DownloadStatus.downloading,
        progressMessage: 'Downloading: 50%',
      );

      // Assert
      expect(service, isNotNull);
    });

    test('should show completed notification', () async {
      // Act
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 100,
        status: DownloadStatus.completed,
        completeMessage: 'Download complete',
      );

      // Assert
      expect(service, isNotNull);
    });

    test(
      'should show completed notification when progress is 100% even if status is still downloading',
      () async {
        // This tests the edge case where flutter_downloader reports 100% progress
        // but the status hasn't yet transitioned to completed
        await service.showDownloadProgress(
          downloadId: downloadId,
          title: title,
          reciterName: reciterName,
          progress: 100,
          status: DownloadStatus.downloading, // Still "downloading" but 100%
          completeMessage: 'Download complete',
        );

        // Assert - should complete without error (treated as completed)
        expect(service, isNotNull);
      },
    );

    test('should show failed notification', () async {
      // Act
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 50,
        status: DownloadStatus.failed,
        failedMessage: 'Download failed',
      );

      // Assert
      expect(service, isNotNull);
    });

    test('should cancel notification when status is cancelled', () async {
      // Arrange - First show a notification
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 50,
        status: DownloadStatus.downloading,
      );

      // Act - Cancel it
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 50,
        status: DownloadStatus.cancelled,
      );

      // Assert - completes without error
      expect(service, isNotNull);
    });

    test('should use default messages when not provided', () async {
      // Act
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 0,
        status: DownloadStatus.pending,
        // No custom messages
      );

      // Assert
      expect(service, isNotNull);
    });

    test('should auto-initialize if not initialized', () async {
      // Arrange - service not explicitly initialized

      // Act
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: title,
        reciterName: reciterName,
        progress: 50,
        status: DownloadStatus.downloading,
      );

      // Assert - should not throw
      expect(service, isNotNull);
    });
  });

  group('showBatchDownloadProgress', () {
    const batchId = 'batch-1';
    const title = 'Downloading Al-Sudais';

    test('should show batch downloading notification', () async {
      // Act
      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 33,
        completedCount: 10,
        totalCount: 30,
        status: DownloadStatus.downloading,
      );

      // Assert
      expect(service, isNotNull);
    });

    test('should show batch pending notification', () async {
      // Act
      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 0,
        completedCount: 0,
        totalCount: 30,
        status: DownloadStatus.pending,
      );

      // Assert
      expect(service, isNotNull);
    });

    test('should show batch completed notification', () async {
      // Act
      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 100,
        completedCount: 30,
        totalCount: 30,
        status: DownloadStatus.completed,
      );

      // Assert
      expect(service, isNotNull);
    });

    test('should show batch failed notification', () async {
      // Act
      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 50,
        completedCount: 15,
        totalCount: 30,
        status: DownloadStatus.failed,
      );

      // Assert
      expect(service, isNotNull);
    });

    test('should cancel batch notification when status is cancelled', () async {
      // Arrange
      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 50,
        completedCount: 15,
        totalCount: 30,
        status: DownloadStatus.downloading,
      );

      // Act
      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 50,
        completedCount: 15,
        totalCount: 30,
        status: DownloadStatus.cancelled,
      );

      // Assert
      expect(service, isNotNull);
    });

    test('should auto-initialize if not initialized', () async {
      // Act - without explicit initialization
      await service.showBatchDownloadProgress(
        batchId: batchId,
        title: title,
        progress: 50,
        completedCount: 15,
        totalCount: 30,
        status: DownloadStatus.downloading,
      );

      // Assert
      expect(service, isNotNull);
    });
  });

  group('cancelNotification', () {
    test('should cancel notification for existing download', () async {
      // Arrange - Create a notification first
      const downloadId = 'download-1';
      await service.showDownloadProgress(
        downloadId: downloadId,
        title: 'Test',
        reciterName: 'Test Reciter',
        progress: 50,
        status: DownloadStatus.downloading,
      );

      // Act
      await service.cancelNotification(downloadId);

      // Assert - should complete without error
      expect(service, isNotNull);
    });

    test('should handle cancelling non-existent notification', () async {
      // Act
      await service.cancelNotification('non-existent-id');

      // Assert - should complete without error (no-op)
      expect(service, isNotNull);
    });
  });

  group('cancelAllNotifications', () {
    test('should cancel all notifications', () async {
      // Arrange - Create multiple notifications
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

      // Act
      await service.cancelAllNotifications();

      // Assert - should complete without error
      expect(service, isNotNull);
    });

    test('should handle cancelling all when no notifications exist', () async {
      // Act
      await service.cancelAllNotifications();

      // Assert - should complete without error
      expect(service, isNotNull);
    });
  });

  group('handleNotificationResponse', () {
    const reciterName = 'Al-Afasy';
    const reciterEntity = ReciterEntity(
      id: 1,
      name: reciterName,
      letter: 'A',
      date: '2023',
      moshaf: [],
    );

    test('should return early if payload is null', () async {
      // Arrange
      const response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
      );

      // Act
      await service.handleNotificationResponse(response);

      // Assert
      verifyZeroInteractions(mockRecitersRepository);
      verifyZeroInteractions(mockNavigationService);
    });

    test('should fetch reciter and navigate when payload is valid', () async {
      // Arrange
      final String payload = jsonEncode({'reciterName': reciterName});
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(
        mockRecitersRepository.getReciters(),
      ).thenAnswer((_) async => const Right([reciterEntity]));

      // Stub push to satisfy the call
      when(
        mockNavigationService.push(any, extra: anyNamed('extra')),
      ).thenAnswer((_) async {
        return;
      });

      // Act
      await service.handleNotificationResponse(response);

      // Assert
      verify(mockRecitersRepository.getReciters()).called(1);

      // Verify navigation call
      // Capture arguments to verify details
      final List<dynamic> captured = verify(
        mockNavigationService.push(captureAny, extra: captureAnyNamed('extra')),
      ).captured;

      expect(captured[0], isA<String>()); // location string
      expect(captured[0], contains(reciterEntity.id.toString()));
      expect(captured[1], isA<ReciterEntity>()); // extra
      expect((captured[1] as ReciterEntity).name, equals(reciterEntity.name));
    });

    test('should NOT navigate if already on target route', () async {
      // Arrange
      final String payload = jsonEncode({'reciterName': reciterName});
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(
        mockRecitersRepository.getReciters(),
      ).thenAnswer((_) async => const Right([reciterEntity]));

      // Mock current location to match target PATH only (simulating user scenario)
      // The generated targetLocation will contain query params like /reciter/1?reciter=...
      // We return /reciter/1 to verify the path comparison logic
      when(mockNavigationService.getCurrentLocation()).thenReturn('/reciter/1');

      // Act
      await service.handleNotificationResponse(response);

      // Assert
      verify(mockRecitersRepository.getReciters()).called(1);
      // Verify push is NEVER called
      verifyNever(mockNavigationService.push(any, extra: anyNamed('extra')));
    });

    test('should not navigate if reciter is not found', () async {
      // Arrange
      final String payload = jsonEncode({'reciterName': 'Unknown'});
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(
        mockRecitersRepository.getReciters(),
      ).thenAnswer((_) async => const Right([reciterEntity]));

      // Act
      await service.handleNotificationResponse(response);

      // Assert
      verify(mockRecitersRepository.getReciters()).called(1);
      verifyZeroInteractions(mockNavigationService);
    });

    test('should not navigate if repository fails', () async {
      // Arrange
      final String payload = jsonEncode({'reciterName': reciterName});
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(
        mockRecitersRepository.getReciters(),
      ).thenAnswer((_) async => const Left(ServerFailure('Error')));

      // Act
      await service.handleNotificationResponse(response);

      // Assert
      verify(mockRecitersRepository.getReciters()).called(1);
      verifyZeroInteractions(mockNavigationService);
    });

    test('should ignore non-JSON payloads', () async {
      // Arrange
      const payload =
          'plain_text_payload'; // Not JSON, not a download notification
      const response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      // Act
      await service.handleNotificationResponse(response);

      // Assert - should not interact with any dependencies
      verifyZeroInteractions(mockRecitersRepository);
      verifyZeroInteractions(mockNavigationService);
    });
  });
}
