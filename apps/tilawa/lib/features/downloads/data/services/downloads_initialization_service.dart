import 'dart:ui';

import 'package:injectable/injectable.dart';
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/logging/app_logger.dart';
=======
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
>>>>>>> master
import 'package:tilawa_core/config/language_config.dart';

import '../../domain/repositories/downloads_repository.dart';
import '../../domain/services/download_notification_service_interface.dart';
import 'batch_download_manager.dart';
import 'download_queue_manager.dart';
<<<<<<< HEAD
=======

final logger = Logger();
>>>>>>> master

@singleton
class DownloadsInitializationService {
  DownloadsInitializationService(
    this._downloadsRepository,
    this._downloadNotificationService,
    this._batchDownloadManager,
    this._downloadQueueManager,
    this._prefs,
  );

  final DownloadsRepository _downloadsRepository;
  final IDownloadNotificationService _downloadNotificationService;
  final BatchDownloadManager _batchDownloadManager;
  final DownloadQueueManager _downloadQueueManager;
  final SharedPreferencesAsync _prefs;

  /// Initialize downloads feature
  /// This checks for any pending or stuck downloads and resumes them
  Future<void> initialize() async {
    try {
      // Set locale from user's persisted preference before any notifications
      await _syncLocaleFromPreferences();

      await _downloadNotificationService.initialize();
      await _batchDownloadManager.initialize();
      await _downloadsRepository.initialize();
      await _downloadsRepository.resumePendingDownloads();
      logger.d('DownloadsInitializationService: Initialization completed');
    } catch (e) {
      logger.e('DownloadsInitializationService: Initialization failed: $e');
    }
  }

  /// Reads the user's persisted language preference and applies it to
  /// both download managers so notifications use the correct locale.
  Future<void> _syncLocaleFromPreferences() async {
    try {
      final String? savedLanguage = await _prefs.getString(
        LanguageConfig.languageKey,
      );
      if (savedLanguage != null && savedLanguage.isNotEmpty) {
        final Locale locale = Locale(savedLanguage);
        _downloadQueueManager.locale = locale;
        _batchDownloadManager.locale = locale;
      }
    } catch (e) {
      logger.d('DownloadsInitializationService: Could not sync locale: $e');
    }
  }
}
