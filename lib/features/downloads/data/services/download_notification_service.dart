import 'dart:convert';
import 'dart:io';
import 'dart:ui'; // or flutter/material.dart

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/foundation.dart'; // for visibleForTesting
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/reciter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../main.dart';
import '../../../../router/app_router_config.dart';
import '../../../../shared/models/reciter_model.dart';
import '../../../reciters/domain/repositories/reciters_repository.dart';
import '../../domain/entities/download_item.dart';

/// Service for showing custom download notifications with proper title formatting
@lazySingleton
class DownloadNotificationService {
  DownloadNotificationService(this._recitersRepository, this._navigator);

  final RecitersRepository _recitersRepository;
  final NavigationService _navigator;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Channel ID for download notifications
  static const String _downloadChannelId = 'download_progress';
  static const String _downloadChannelName = 'Download Progress';
  static const String _downloadChannelDescription =
      'Shows download progress for Quran audio files';

  /// Map to store notification IDs for each download (using hash of download ID)
  final Map<String, int> _notificationIds = {};

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher_monochrome',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: handleNotificationResponse,
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

  /// Get or create a notification ID for a download
  int _getNotificationId(String downloadId) {
    if (!_notificationIds.containsKey(downloadId)) {
      // Use hashCode modulo a large number to get a unique-ish ID
      _notificationIds[downloadId] = downloadId.hashCode.abs() % 100000;
    }
    return _notificationIds[downloadId]!;
  }

  /// Show a download progress notification
  ///
  /// [pendingMessage] - Localized message for pending status (e.g., "Waiting to start...")
  /// [progressMessage] - Localized message for progress (e.g., "Downloading: 50%")
  /// [completeMessage] - Localized message for completed status
  /// [failedMessage] - Localized message for failed status
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
    if (!_initialized) {
      await initialize();
    }

    final int notificationId = _getNotificationId(downloadId);
    final notificationTitle = '$reciterName - $title';

    try {
      if (status == DownloadStatus.downloading ||
          status == DownloadStatus.pending) {
        // Show progress notification
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
          color: const Color(0xFF1AADC5),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        );

        final notificationDetails = NotificationDetails(
          android: androidDetails,
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
      } else if (status == DownloadStatus.completed) {
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

  /// Show a completed download notification
  Future<void> _showCompletedNotification({
    required int notificationId,
    required String title,
    required String message,
    required String reciterName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _downloadChannelId,
      _downloadChannelName,
      channelDescription: _downloadChannelDescription,
      color: Color(0xFF1AADC5),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      notificationId,
      title,
      message,
      notificationDetails,
      payload: jsonEncode({'reciterName': reciterName}),
    );
  }

  /// Show a failed download notification
  Future<void> _showFailedNotification({
    required int notificationId,
    required String title,
    required String message,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _downloadChannelId,
      _downloadChannelName,
      channelDescription: _downloadChannelDescription,
      color: Color(0xFF1AADC5),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      notificationId,
      title,
      message,
      notificationDetails,
    );
  }

  /// Cancel a download notification
  Future<void> cancelNotification(String downloadId) async {
    final int? notificationId = _notificationIds[downloadId];
    if (notificationId != null) {
      await _notifications.cancel(notificationId);
      _notificationIds.remove(downloadId);
    }
  }

  /// Cancel all download notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    _notificationIds.clear();
  }

  /// Handle notification tap
  @visibleForTesting
  Future<void> handleNotificationResponse(NotificationResponse response) async {
    final String? payload = response.payload;
    if (payload == null) {
      return;
    }

    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final String? reciterName = data['reciterName'];

      if (reciterName != null) {
        // Don't wait for navigation
        await _navigateToReciter(reciterName);
      }
    } catch (e) {
      logger.e(
        'DoownloadNotificationService: Error handling notification tap: $e',
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

            final Reciter reciter = _mapEntityToModel(reciterEntity);
            final reciterId = reciter.id.toString();
            final String location = ReciterDetailsRoute(
              reciterId: reciterId,
              reciter: reciter,
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

  /// Map ReciterEntity (Domain) to Reciter (Model/Data) using manual mapping
  /// because they are separate classes in this project architecture.
  Reciter _mapEntityToModel(ReciterEntity entity) {
    return Reciter(
      id: entity.id,
      name: entity.name,
      letter: entity.letter,
      date: entity.date,
      moshaf: entity.moshaf
          .map(
            (m) => Mosahf(
              id: m.id,
              name: m.name,
              server: m.server,
              surahTotal: m.surahTotal,
              moshafType: m.moshafType,
              surahList: m.surahList,
            ),
          )
          .toList(),
    );
  }
}
