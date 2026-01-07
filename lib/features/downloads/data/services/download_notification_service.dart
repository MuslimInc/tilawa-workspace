import 'dart:convert';
import 'dart:io';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/config/notification_config.dart';
import '../../../../core/entities/reciter_entity.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/interfaces/notification_dispatcher_interface.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../main.dart';
import '../../../../router/app_router_config.dart';
import '../../../reciters/domain/repositories/reciters_repository.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/services/download_notification_service_interface.dart';

/// Service for showing custom download notifications with proper title formatting
@LazySingleton(as: IDownloadNotificationService)
class DownloadNotificationService implements IDownloadNotificationService {
  DownloadNotificationService(
    this._recitersRepository,
    this._navigator,
    this._dispatcher,
  );

  final RecitersRepository _recitersRepository;
  final NavigationService _navigator;
  final INotificationDispatcher _dispatcher;

  /// Channel ID for download notifications
  static const String _downloadChannelId = 'com.tilawa.app.downloads';
  static const String _downloadChannelName = 'Downloads';
  static const String _downloadChannelDescription = 'Shows download progress';

  FlutterLocalNotificationsPlugin get _notifications =>
      _dispatcher.notificationsPlugin;

  bool _initialized = false;
  final Map<String, int> _notificationIds = {};

  /// Initialize the notification service
  @override
  Future<void> initialize() async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }

    if (_initialized) {
      return;
    }

    try {
      // Initialize the dispatcher (which initializes the shared notification plugin)
      await _dispatcher.initialize();

      // Register our payload handler with the dispatcher
      // Download notifications use JSON payloads with reciterName
      _dispatcher.registerPayloadHandler(
        serviceId: 'downloads',
        matcher: _isDownloadPayload,
        handler: handleNotificationResponse,
      );

      // Create notification channel for Android
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _notifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _downloadChannelId,
            _downloadChannelName,
            description: _downloadChannelDescription,
            importance: Importance.low,
            showBadge: false,
          ),
        );
      }

      _initialized = true;
      logger.d('[DownloadNotificationService] Initialized');
    } catch (e) {
      logger.e('[DownloadNotificationService] Initialization failed: $e');
    }
  }

  /// Check if a payload belongs to download notifications
  bool _isDownloadPayload(String? payload) {
    if (payload == null) return false;
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      return data.containsKey('reciterName');
    } catch (_) {
      return false;
    }
  }

  /// Show a download progress notification
  ///
  /// [pendingMessage] - Localized message for pending status (e.g., "Waiting to start...")
  /// [progressMessage] - Localized message for progress (e.g., "Downloading: 50%")
  /// [completeMessage] - Localized message for completed status
  /// [failedMessage] - Localized message for failed status
  @override
  Future<void> showDownloadProgress({
    required String downloadId,
    required String title,
    required String reciterName,
    required int progress,
    required DownloadStatus status,
    String? pendingMessage,
    String? progressMessage,
    String? completeMessage,
    String? failedMessage,
  }) async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    final int notificationId = _getNotificationId(downloadId);
    final notificationTitle = '$reciterName - $title';

    try {
      // Treat 100% progress as completed even if status hasn't updated yet
      final bool isEffectivelyCompleted =
          status == DownloadStatus.completed ||
          (status == DownloadStatus.downloading && progress >= 100);

      if (!isEffectivelyCompleted &&
          (status == DownloadStatus.downloading ||
              status == DownloadStatus.pending)) {
        // Show progress notification (only for < 100%)
        final androidDetails = AndroidNotificationDetails(
          _downloadChannelId,
          _downloadChannelName,
          channelDescription: _downloadChannelDescription,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          onlyAlertOnce: true,
          showProgress: true,
          maxProgress: 100,
          progress: progress,
          category: AndroidNotificationCategory.progress,
          autoCancel: false,
          icon: 'ic_launcher_monochrome',
          color: AppColors.notificationAccent,
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        );

        final notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notifications.show(
          notificationId,
          notificationTitle,
          status == DownloadStatus.pending
              ? (pendingMessage ?? 'Waiting to start...')
              : (progressMessage ?? 'Downloading: $progress%'),
          notificationDetails,
          payload: jsonEncode({'reciterName': reciterName}),
        );
      } else if (isEffectivelyCompleted) {
        // Show completed notification
        await _showCompletedNotification(
          notificationId: notificationId,
          title: notificationTitle,
          message: completeMessage ?? 'Download complete',
          reciterName: reciterName,
        );
      } else if (status == DownloadStatus.failed) {
        // Show failed notification
        await _showFailedNotification(
          notificationId: notificationId,
          title: notificationTitle,
          message: failedMessage ?? 'Download failed',
        );
      } else if (status == DownloadStatus.cancelled) {
        // Cancel/remove the notification
        await cancelNotification(downloadId);
      }
    } catch (e) {
      logger.e('[DownloadNotificationService] Error showing notification: $e');
    }
  }

  /// Show a batch download progress notification
  @override
  Future<void> showBatchDownloadProgress({
    required String batchId,
    required String title,
    required int progress,
    required int completedCount,
    required int totalCount,
    required DownloadStatus status,
  }) async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    // Use a specific ID range for batches or hash
    final int notificationId = _getNotificationId(batchId);

    try {
      if (status == DownloadStatus.downloading ||
          status == DownloadStatus.pending) {
        final androidDetails = AndroidNotificationDetails(
          _downloadChannelId,
          _downloadChannelName,
          channelDescription: _downloadChannelDescription,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          onlyAlertOnce: true,
          showProgress: true,
          maxProgress: 100,
          progress: progress,
          category: AndroidNotificationCategory.progress,
          autoCancel: false,
          icon: 'ic_launcher_monochrome',
          color: AppColors.notificationAccent,
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        );

        final notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notifications.show(
          notificationId,
          title,
          'Progress: $completedCount/$totalCount ($progress%)',
          notificationDetails,
        );
      } else if (status == DownloadStatus.completed) {
        await _showCompletedNotification(
          notificationId: notificationId,
          title: title,
          message: 'All $totalCount files downloaded successfully',
          reciterName: '', // Opens default screen or handled differently
        );
      } else if (status == DownloadStatus.failed) {
        await _showFailedNotification(
          notificationId: notificationId,
          title: title,
          message: 'Batch download failed',
        );
      } else if (status == DownloadStatus.cancelled) {
        await cancelNotification(batchId);
      }
    } catch (e) {
      logger.e(
        '[DownloadNotificationService] Error showing batch notification: $e',
      );
    }
  }

  /// Cancel a download notification
  @override
  Future<void> cancelNotification(String downloadId) async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }

    final int? notificationId = _notificationIds[downloadId];
    if (notificationId != null) {
      await _notifications.cancel(notificationId);
      _notificationIds.remove(downloadId);
    }
  }

  /// Cancel all download notifications
  @override
  Future<void> cancelAllNotifications() async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }

    await _notifications.cancelAll();
    _notificationIds.clear();
  }

  /// Handle notification tap
  @override
  @visibleForTesting
  Future<void> handleNotificationResponse(NotificationResponse response) async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }

    final String? payload = response.payload;
    if (payload == null) {
      return;
    }

    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final String? reciterName = data['reciterName'];

      if (reciterName != null) {
        await _navigateToReciter(reciterName);
      }
    } on FormatException catch (e) {
      // Not a JSON payload - not a download notification, ignore it
      // Other notification services handle their own payloads independently
      logger.d(
        'DownloadNotificationService: Ignoring non-download notification due to invalid JSON payload. '
        'Payload: $payload, error: $e',
      );
    } catch (e) {
      logger.e(
        'DownloadNotificationService: Error handling notification tap: $e',
      );
    }
  }

  /// Navigate to reciter details screen
  Future<void> _navigateToReciter(String reciterName) async {
    // Use injected navigator
    try {
      final Either<Failure, List<ReciterEntity>> result =
          await _recitersRepository.getReciters();

      result.fold(
        (failure) => logger.e(
          'DownloadNotificationService: Failed to fetch reciters: $failure',
        ),
        (reciters) {
          try {
            final ReciterEntity reciterEntity = reciters.firstWhere(
              (r) => r.name == reciterName,
            );

            final reciter = reciterEntity;
            final reciterId = reciter.id.toString();
            final String location = ReciterDetailsRoute(
              reciterId: reciterId,
              $extra: reciter,
            ).location;

            final String? currentLocation = _navigator.getCurrentLocation();
            if (currentLocation != null) {
              final Uri currentUri = Uri.parse(currentLocation);
              final Uri targetUri = Uri.parse(location);
              if (currentUri.path == targetUri.path) {
                return;
              }
            }

            _navigator.push(location, extra: reciter);
          } catch (e) {
            logger.w(
              'DownloadNotificationService: Reciter not found for name: $reciterName',
            );
          }
        },
      );
    } catch (e) {
      logger.e('DownloadNotificationService: Navigation error: $e');
    }
  }

  /// Helper to generate a consistent notification ID from string ID
  int _getNotificationId(String id) {
    return _notificationIds.putIfAbsent(id, () => id.hashCode);
  }

  /// Helper to show completed notification
  Future<void> _showCompletedNotification({
    required int notificationId,
    required String title,
    required String message,
    required String reciterName,
  }) async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        _downloadChannelId,
        _downloadChannelName,
        channelDescription: _downloadChannelDescription,
        icon: 'ic_launcher_monochrome',
        color: AppColors.notificationAccent,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        notificationId,
        title,
        message,
        notificationDetails,
        payload: jsonEncode({'reciterName': reciterName}),
      );
    } catch (e) {
      logger.e('[DownloadNotificationService] Error showing completion: $e');
    }
  }

  /// Helper to show failed notification
  Future<void> _showFailedNotification({
    required int notificationId,
    required String title,
    required String message,
  }) async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        _downloadChannelId,
        _downloadChannelName,
        channelDescription: _downloadChannelDescription,
        icon: 'ic_launcher_monochrome',
        color: AppColors.error,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        notificationId,
        title,
        message,
        notificationDetails,
      );
    } catch (e) {
      logger.e('[DownloadNotificationService] Error showing failure: $e');
    }
  }
}
