import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/config/notification_config.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/download_item.dart';
import '../../domain/services/download_notification_navigator.dart';
import '../../domain/services/download_notification_service_interface.dart';

/// Service for showing custom download notifications with proper title formatting
@LazySingleton(as: IDownloadNotificationService)
class DownloadNotificationService implements IDownloadNotificationService {
  DownloadNotificationService(this._notificationNavigator, this._dispatcher);

  final DownloadNotificationNavigator _notificationNavigator;
  final INotificationDispatcher _dispatcher;

  /// Channel ID for download notifications
  static const String _downloadChannelId = 'com.tilawa.app.downloads';
  static const String _downloadChannelName = 'Downloads';
  static const String _downloadChannelDescription = 'Shows download progress';

  /// Notification ID block for download progress/completion notifications.
  ///
  /// Must stay below athkar dynamic IDs (11M+) and tasbeeh reminders (13M+).
  static const int notificationIdOffset = 100000;
  static const int notificationIdRangeEndExclusive = 1000000;

  FlutterLocalNotificationsPlugin get _notifications =>
      _dispatcher.notificationsPlugin;

  bool _initialized = false;
  final Map<String, int> _notificationIds = {};
  final Set<String> _finalizedDownloadIds = {};
  final Map<String, Future<void>> _notificationUpdateChains = {};

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
      // Keep startup path lightweight; high-importance channel creation is
      // deferred centrally in app_startup.
      await _dispatcher.initialize(createHighImportanceChannel: false);

      // Route taps by ID block first (failed/batch notifications may omit
      // payload), then fall back to payload matching for legacy IDs.
      _dispatcher.registerIdRangeHandler(
        serviceId: 'downloads',
        minIdInclusive: notificationIdOffset,
        maxIdExclusive: notificationIdRangeEndExclusive,
        handler: (response) => handleNotificationTap(response.payload),
      );
      _dispatcher.registerPayloadHandler(
        serviceId: 'downloads',
        matcher: _isDownloadPayload,
        handler: (response) => handleNotificationTap(response.payload),
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
            ledColor: AppColors.notificationAccent,
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
    if (payload == null) {
      return false;
    }
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      return data.containsKey('reciterId') ||
          data.containsKey('reciterName') ||
          data['type'] == 'download';
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
    int? reciterId,
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

    final String stableId = _normalizeDownloadId(downloadId);
    final Future<void> previous =
        _notificationUpdateChains[stableId] ?? Future<void>.value();
    final Future<void> next = previous
        .catchError((Object _) {})
        .then(
          (_) => _showDownloadProgressImpl(
            stableId: stableId,
            downloadId: downloadId,
            title: title,
            reciterName: reciterName,
            reciterId: reciterId,
            progress: progress,
            status: status,
            pendingMessage: pendingMessage,
            progressMessage: progressMessage,
            completeMessage: completeMessage,
            failedMessage: failedMessage,
          ),
        );

    _notificationUpdateChains[stableId] = next;
    try {
      await next;
    } finally {
      if (identical(_notificationUpdateChains[stableId], next)) {
        _notificationUpdateChains.remove(stableId);
      }
    }
  }

  Future<void> _showDownloadProgressImpl({
    required String stableId,
    required String downloadId,
    required String title,
    required String reciterName,
    int? reciterId,
    required int progress,
    required DownloadStatus status,
    String? pendingMessage,
    String? progressMessage,
    String? completeMessage,
    String? failedMessage,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (status == DownloadStatus.pending) {
      _finalizedDownloadIds.remove(stableId);
    }

    final bool isTerminal =
        status == DownloadStatus.completed ||
        status == DownloadStatus.failed ||
        status == DownloadStatus.cancelled ||
        status == DownloadStatus.paused;

    if (!isTerminal && _finalizedDownloadIds.contains(stableId)) {
      logger.d(
        '[DownloadNotificationService] Ignoring stale progress for $stableId '
        '(status=$status progress=$progress)',
      );
      return;
    }

    final int notificationId = _getNotificationId(downloadId);
    final notificationTitle = '$reciterName - $title';

    try {
      // Treat 100% progress as completed even if status hasn't updated yet
      final bool isEffectivelyCompleted =
          status == DownloadStatus.completed ||
          (status == DownloadStatus.downloading && progress >= 100);

      if (isEffectivelyCompleted || status == DownloadStatus.failed) {
        _finalizedDownloadIds.add(stableId);
        // Clear ongoing progress bar before showing terminal state.
        await _notifications.cancel(id: notificationId);
      }

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
          icon: NotificationConfig.androidSmallIcon,
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
          id: notificationId,
          title: notificationTitle,
          body: status == DownloadStatus.pending
              ? (pendingMessage ?? 'Waiting to start...')
              : (progressMessage ?? 'Downloading: $progress%'),
          notificationDetails: notificationDetails,
          payload: _buildNotificationPayload(
            reciterId: reciterId,
            reciterName: reciterName,
          ),
        );
      } else if (isEffectivelyCompleted) {
        // Show completed notification
        await _showCompletedNotification(
          notificationId: notificationId,
          title: notificationTitle,
          message: completeMessage ?? 'Download complete',
          reciterId: reciterId,
          reciterName: reciterName,
        );
      } else if (status == DownloadStatus.failed) {
        // Show failed notification
        await _showFailedNotification(
          notificationId: notificationId,
          title: notificationTitle,
          message: failedMessage ?? 'Download failed',
          reciterId: reciterId,
          reciterName: reciterName,
        );
      } else if (status == DownloadStatus.cancelled ||
          status == DownloadStatus.paused) {
        _finalizedDownloadIds.add(stableId);
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

    // Use a specific ID range for batches or hash
    final int notificationId = _getNotificationId(batchId);

    try {
      // Mirror single-download logic: 100% with all items done means complete.
      final bool isEffectivelyCompleted =
          status == DownloadStatus.completed ||
          (status == DownloadStatus.downloading &&
              progress >= 100 &&
              totalCount > 0 &&
              completedCount >= totalCount);

      if (!isEffectivelyCompleted &&
          (status == DownloadStatus.downloading ||
              status == DownloadStatus.pending)) {
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
          icon: NotificationConfig.androidSmallIcon,
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
          id: notificationId,
          title: title,
          body:
              progressMessage ??
              'Progress: $completedCount/$totalCount ($progress%)',
          notificationDetails: notificationDetails,
          payload: _fallbackDownloadPayload,
        );
      } else if (isEffectivelyCompleted) {
        await _showCompletedNotification(
          notificationId: notificationId,
          title: title,
          message:
              completeMessage ??
              'All $totalCount files downloaded successfully',
          reciterName: '', // Opens default screen or handled differently
        );
      } else if (status == DownloadStatus.failed) {
        await _showFailedNotification(
          notificationId: notificationId,
          title: title,
          message: failedMessage ?? 'Batch download failed',
        );
      } else if (status == DownloadStatus.cancelled ||
          status == DownloadStatus.paused) {
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

    final String stableId = _normalizeDownloadId(downloadId);
    final int notificationId = stableNotificationIdFor(stableId);
    await _notifications.cancel(id: notificationId);
    _notificationIds.remove(stableId);
    _finalizedDownloadIds.add(stableId);
  }

  /// Cancel all download notifications
  ///
  /// Only cancels notifications owned by this service (tracked in
  /// [_notificationIds]). Does NOT call `cancelAll()` on the shared
  /// notification plugin to avoid removing notifications from other
  /// services (e.g., athkar reminders).
  @override
  Future<void> cancelAllNotifications() async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }

    for (final int id in _notificationIds.values) {
      await _notifications.cancel(id: id);
    }
    _notificationIds.clear();
    _finalizedDownloadIds.clear();
    _notificationUpdateChains.clear();
  }

  /// Handle notification tap
  @override
  @visibleForTesting
  Future<void> handleNotificationTap(String? payload) async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }

    if (payload == null) {
      return;
    }

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final String? reciterId = switch (data['reciterId']) {
        final int value => value.toString(),
        final String value when value.isNotEmpty => value,
        _ => null,
      };
      final String? reciterName = data['reciterName'] as String?;

      if (reciterId != null ||
          (reciterName != null && reciterName.isNotEmpty)) {
        await _notificationNavigator.navigateToReciter(
          reciterId: reciterId,
          reciterName: reciterName,
        );
      } else {}
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

  String? _buildNotificationPayload({int? reciterId, String? reciterName}) {
    if (reciterId == null && (reciterName == null || reciterName.isEmpty)) {
      return null;
    }

    return jsonEncode({
      'type': 'reciter',
      if (reciterId != null) 'data': reciterId.toString(),
      'reciterId': ?reciterId,
      if (reciterName != null && reciterName.isNotEmpty)
        'reciterName': reciterName,
    });
  }

  /// Normalize download IDs/URLs so progress and completion share one notification.
  String _normalizeDownloadId(String id) => normalizeDownloadId(id);

  /// Shared normalization for stable notification IDs across process restarts.
  @visibleForTesting
  static String normalizeDownloadId(String id) {
    final String trimmed = id.trim();
    try {
      final Uri uri = Uri.parse(trimmed);
      final String normalizedPath = uri.path.replaceAll(RegExp('/+'), '/');
      return uri.replace(path: normalizedPath).toString();
    } catch (_) {
      return trimmed;
    }
  }

  /// Deterministic Android notification ID for a download key.
  ///
  /// Survives hot restart so progress updates and cancellation target the same
  /// notification instead of leaving orphaned ongoing progress bars.
  @visibleForTesting
  static int stableNotificationIdFor(String downloadId) {
    final String stableId = normalizeDownloadId(downloadId);
    var hash = 0;
    for (final int unit in stableId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    const int range = notificationIdRangeEndExclusive - notificationIdOffset;
    return notificationIdOffset + (hash % range);
  }

  int _getNotificationId(String id) {
    final String stableId = _normalizeDownloadId(id);
    final int notificationId = stableNotificationIdFor(stableId);
    _notificationIds[stableId] = notificationId;
    return notificationId;
  }

  /// Helper to show completed notification
  Future<void> _showCompletedNotification({
    required int notificationId,
    required String title,
    required String message,
    int? reciterId,
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
        icon: NotificationConfig.androidSmallIcon,
        color: AppColors.notificationAccent,
        ongoing: false,
        showProgress: false,
        autoCancel: true,
        onlyAlertOnce: false,
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
        id: notificationId,
        title: title,
        body: message,
        notificationDetails: notificationDetails,
        payload: _buildNotificationPayload(
          reciterId: reciterId,
          reciterName: reciterName,
        ),
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
    int? reciterId,
    String? reciterName,
  }) async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        _downloadChannelId,
        _downloadChannelName,
        channelDescription: _downloadChannelDescription,
        icon: NotificationConfig.androidSmallIcon,
        color: AppColors.error,
        ongoing: false,
        showProgress: false,
        autoCancel: true,
        onlyAlertOnce: false,
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
        id: notificationId,
        title: title,
        body: message,
        notificationDetails: notificationDetails,
        payload:
            _buildNotificationPayload(
              reciterId: reciterId,
              reciterName: reciterName,
            ) ??
            _fallbackDownloadPayload,
      );
    } catch (e) {
      logger.e('[DownloadNotificationService] Error showing failure: $e');
    }
  }

  static const String _fallbackDownloadPayload = '{"type":"download"}';
}
