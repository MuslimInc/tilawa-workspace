import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../main.dart';
import '../../../../shared/audio/audio_player_handler.dart';
import '../../../premium/domain/repositories/premium_repository.dart';
import '../../data/services/download_service.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/repositories/downloads_repository.dart';
import '../../domain/usecases/clear_all_downloads_use_case.dart';
import '../../domain/usecases/delete_download_use_case.dart';
import '../../domain/usecases/delete_reciter_downloads_use_case.dart';
import '../../domain/usecases/download_surah_use_case.dart';
import '../../domain/usecases/get_downloads_by_reciter_use_case.dart';

part 'downloads_bloc.freezed.dart';
part 'downloads_event.dart';
part 'downloads_state.dart';

/// Event transformer for debouncing events
EventTransformer<T> debounce<T>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

@injectable
class DownloadsBloc extends HydratedBloc<DownloadsEvent, DownloadsState> {
  DownloadsBloc({
    required GetDownloadsByReciterUseCase getDownloadsByReciter,
    required DownloadSurahUseCase downloadSurah,
    required DeleteDownloadUseCase deleteDownload,
    required DeleteReciterDownloadsUseCase deleteReciterDownloads,
    required ClearAllDownloadsUseCase clearAllDownloads,
    required DownloadsRepository downloadsRepository,
    required PremiumRepository premiumRepository,
    required AudioPlayerHandler audioPlayerHandler,
    required AnalyticsService analyticsService,
  }) : _getDownloadsByReciter = getDownloadsByReciter,
       _downloadSurah = downloadSurah,
       _deleteDownload = deleteDownload,
       _deleteReciterDownloads = deleteReciterDownloads,
       _clearAllDownloads = clearAllDownloads,
       _downloadsRepository = downloadsRepository,
       _premiumRepository = premiumRepository,
       _audioPlayerHandler = audioPlayerHandler,
       _analyticsService = analyticsService,
       super(const DownloadsState.initial()) {
    on<LoadDownloads>(_onLoadDownloads);
    on<DownloadSurahEvent>(_onDownloadSurah);
    on<DeleteDownloadEvent>(_onDeleteDownload);
    on<DeleteReciterDownloads>(_onDeleteReciterDownloads);
    on<ClearAllDownloads>(_onClearAllDownloads);
    on<CheckSurahDownloadedEvent>(_onCheckSurahDownloaded);
    on<ValidateDownloadedFileEvent>(_onValidateDownloadedFile);
    on<GetValidCompletedDownloadsEvent>(_onGetValidCompletedDownloads);
    on<PlayDownloadedSurahEvent>(_onPlayDownloadedSurah);
    on<PlayAllDownloadsEvent>(_onPlayAllDownloads);
    on<CheckPremiumAccessEvent>(_onCheckPremiumAccess);
    on<RetryDownloadEvent>(_onRetryDownload);
    on<RefreshDownloadsProgress>(
      _onRefreshDownloadsProgress,
      transformer: debounce(const Duration(milliseconds: 1000)),
    );

    // Listen to download progress
    _listenToProgress();
  }
  final GetDownloadsByReciterUseCase _getDownloadsByReciter;
  final DownloadSurahUseCase _downloadSurah;
  final DeleteDownloadUseCase _deleteDownload;
  final DeleteReciterDownloadsUseCase _deleteReciterDownloads;
  final ClearAllDownloadsUseCase _clearAllDownloads;
  final DownloadsRepository _downloadsRepository;
  final PremiumRepository _premiumRepository;
  final AudioPlayerHandler _audioPlayerHandler;
  final AnalyticsService _analyticsService;

  StreamSubscription<DownloadProgress>? _progressSubscription;
  Timer? _progressReloadTimer;

  // Broadcast stream controller for download progress updates
  // This allows multiple widgets to listen to individual download progress
  final StreamController<DownloadProgress> _downloadProgressController =
      StreamController<DownloadProgress>.broadcast();

  /// Exposes a broadcast stream of download progress updates.
  ///
  /// Widgets can listen to this stream to get real-time progress updates
  /// for all downloads without needing to reload the entire downloads list.
  ///
  /// Example usage:
  /// ```dart
  /// bloc.downloadProgressStream
  ///   .where((progress) => progress.id == downloadId)
  ///   .listen((progress) {
  ///     // Update UI with progress
  ///   });
  /// ```
  Stream<DownloadProgress> get downloadProgressStream =>
      _downloadProgressController.stream;

  /// Gets a filtered stream for a specific download ID.
  ///
  /// This is a convenience method that filters the broadcast stream
  /// to only emit progress updates for the specified download.
  ///
  /// Example:
  /// ```dart
  /// bloc.getDownloadProgressStream(downloadId).listen((progress) {
  ///   setState(() {
  ///     _progress = progress.progress;
  ///     _status = progress.status;
  ///   });
  /// });
  /// ```
  Stream<DownloadProgress> getDownloadProgressStream(String downloadId) {
    return _downloadProgressController.stream.where(
      (progress) => progress.id == downloadId,
    );
  }

  /// Listens to download progress updates from the DownloadService.
  ///
  /// This method sets up a stream subscription to monitor download progress
  /// and update the UI accordingly. It includes:
  /// - Error handling for platform-specific exceptions
  /// - Debouncing to prevent excessive UI updates
  /// - Immediate updates for completion/failure states
  /// - Proper cleanup on subscription cancellation
  void _listenToProgress() {
    try {
      _progressSubscription?.cancel(); // Cancel any existing subscription

      _progressSubscription = DownloadService.globalProgressStream.listen(
        _handleProgressUpdate,
        onError: _handleProgressError,
        onDone: _handleProgressDone,
        cancelOnError: false, // Continue listening even after errors
      );

      logger.d('[DownloadsBloc] Progress stream listener initialized');
    } on MissingPluginException catch (e) {
      // In test environment, platform channels are not available
      // This is expected and should not cause the bloc to fail
      logger.d(
        '[DownloadsBloc] Progress stream listening skipped - '
        'platform channels not available (test environment): $e',
      );
    } on StateError catch (e) {
      // Stream has already been listened to or closed
      logger.w('[DownloadsBloc] Progress stream state error: $e');
    } catch (e, stackTrace) {
      // Any other unexpected error
      logger.e(
        '[DownloadsBloc] Unexpected error setting up progress stream',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handles a single progress update from the download service.
  void _handleProgressUpdate(DownloadProgress progress) {
    try {
      // Broadcast progress update to all listeners
      // This allows widgets to listen for specific download progress updates
      if (!_downloadProgressController.isClosed) {
        _downloadProgressController.add(progress);
      }

      // Update the download progress in the repository
      _downloadsRepository.updateDownloadProgress(
        progress.id,
        progress.status,
        progress.progress,
        progress.downloadedSize,
        progress.fileSize,
      );

      // Only reload if we're in a loaded state to avoid unnecessary reloads
      if (state is! DownloadsLoaded) {
        return;
      }

      // Immediate reload for terminal states (completed/failed/cancelled)
      if (_isTerminalStatus(progress.status)) {
        _cancelProgressTimer();
        add(const LoadDownloads());
        logger.d(
          '[DownloadsBloc] Terminal status ${progress.status} for ${progress.id}, '
          'triggering immediate reload',
        );
        return;
      }

      // Debounce in-progress updates to avoid excessive reloads
      _scheduleProgressRefresh();
    } catch (e, stackTrace) {
      logger.e(
        '[DownloadsBloc] Error handling progress update',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handles errors from the progress stream.
  void _handleProgressError(Object error, StackTrace stackTrace) {
    logger.e(
      '[DownloadsBloc] Progress stream error',
      error: error,
      stackTrace: stackTrace,
    );
    // Don't add error state here - we want downloads list to remain visible
    // The stream will continue listening due to cancelOnError: false
  }

  /// Handles completion of the progress stream.
  void _handleProgressDone() {
    logger.d('[DownloadsBloc] Progress stream completed');
    _cancelProgressTimer();
    // Stream completed - might want to attempt reconnection
    // For now, just log it
  }

  /// Checks if a download status is terminal (no more updates expected).
  bool _isTerminalStatus(DownloadStatus status) {
    return status == DownloadStatus.completed ||
        status == DownloadStatus.failed ||
        status == DownloadStatus.cancelled;
  }

  /// Schedules a refresh of the downloads list after a debounce period.
  ///
  /// This prevents excessive UI updates during rapid progress changes.
  /// Cancels any pending refresh and schedules a new one.
  void _scheduleProgressRefresh() {
    _cancelProgressTimer();

    // Debounce: wait 150ms after last progress update before reloading
    // This provides smooth updates (~6-7 times per second)
    _progressReloadTimer = Timer(const Duration(milliseconds: 150), () {
      if (!isClosed) {
        add(const DownloadsEvent.refreshDownloadsProgress());
      }
    });
  }

  /// Cancels the pending progress reload timer if it exists.
  void _cancelProgressTimer() {
    _progressReloadTimer?.cancel();
    _progressReloadTimer = null;
  }

  Future<void> _onRefreshDownloadsProgress(
    RefreshDownloadsProgress event,
    Emitter<DownloadsState> emit,
  ) async {
    // Only refresh if we're in loaded state
    if (state is! DownloadsLoaded) {
      return;
    }

    final Either<Failure, Map<String, List<DownloadItem>>> result =
        await _getDownloadsByReciter();
    result.fold(
      (failure) {
        // Don't show error for progress updates, just log it
        logger.e('Failed to refresh downloads progress: ${failure.message}');
      },
      (downloads) {
        // Emit loaded state directly with updated downloads (no loading state)
        emit(DownloadsState.loaded(downloads));
      },
    );
  }

  @override
  Future<void> close() async {
    _progressReloadTimer?.cancel();
    await _progressSubscription?.cancel();
    await _downloadProgressController.close();
    return super.close();
  }

  Future<void> _onLoadDownloads(
    LoadDownloads event,
    Emitter<DownloadsState> emit,
  ) async {
    final Either<Failure, Map<String, List<DownloadItem>>> result =
        await _getDownloadsByReciter();
    await result.fold(
      (failure) async => emit(
        DownloadsState.error(failure.message ?? 'Failed to load downloads'),
      ),
      (downloads) async => emit(DownloadsState.loaded(downloads)),
    );
  }

  Map<String, List<DownloadItem>> _getCurrentDownloads() {
    return state.maybeWhen(
      loaded: (downloads) => downloads,
      downloadStarted: (_, __, ___, downloads) => downloads,
      premiumRequired: (_, downloads) => downloads,
      playbackInitiated: (_, downloads) => downloads,
      orElse: () => {},
    );
  }

  Future<void> _onDownloadSurah(
    DownloadSurahEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    // Check premium access before allowing download
    final bool canDownload = await _premiumRepository.canDownload();
    if (!canDownload) {
      emit(
        DownloadsState.premiumRequired(
          message:
              'Download feature requires premium subscription. Upgrade to unlock unlimited downloads!',
          downloadsByReciter: _getCurrentDownloads(),
        ),
      );
      return;
    }

    // Check if surah is already downloaded
    final bool isAlreadyDownloaded = await _downloadsRepository
        .isSurahDownloaded(event.surahId, event.reciterName);

    // Capture current downloads before potential state change
    final Map<String, List<DownloadItem>> currentDownloads =
        _getCurrentDownloads();

    if (isAlreadyDownloaded) {
      emit(
        DownloadsState.error(
          'Surah "${event.surahTitle}" by ${event.reciterName} is already downloaded',
        ),
      );
      // Restore loaded state to ensure UI displays the list
      emit(DownloadsState.loaded(currentDownloads));
      return;
    }

    // Check if download is currently in progress
    // Note: surahId is the URL, and DownloadService uses URL as the task ID
    try {
      if (await DownloadService.isDownloadActive(event.surahId)) {
        emit(
          DownloadsState.error(
            'Surah "${event.surahTitle}" by ${event.reciterName} is already being downloaded',
          ),
        );
        return;
      }
    } on MissingPluginException {
      // In test environment, platform channels are not available
      // Skip the check and continue with download
      logger.d(
        '[DownloadsBloc] DownloadService.isDownloadActive skipped - platform channels not available (test environment)',
      );
    } catch (e) {
      // Any other error - log and continue
      logger.w('[DownloadsBloc] Error checking if download is active: $e');
    }

    // Create a temporary DownloadItem to represent the download in progress
    final downloadItem = DownloadItem(
      id: '${event.surahId}_${event.reciterName}',
      title: event.surahTitle,
      url: event.surahId,
      reciterName: event.reciterName,
      status: DownloadStatus.downloading,
      progress: 0.0,
      downloadedSize: 0,
      fileSize: 0,
      filePath: '',
      createdAt: DateTime.now(),
    );

    // Emit download started state
    emit(
      DownloadsState.downloadStarted(
        surahId: downloadItem.id.split(
          '_',
        )[0], // Extract surah ID from download ID
        surahTitle: downloadItem.title,
        reciterName: downloadItem.reciterName,
        downloadsByReciter: _getCurrentDownloads(),
      ),
    );

    // Log analytics event for download start
    // Use a formatted ID for analytics purposes
    final analyticsDownloadId =
        '${event.surahId}_${event.reciterName.replaceAll(' ', '_')}';
    await _analyticsService.logDownloadStart(
      analyticsDownloadId,
      fileName: '${event.surahTitle}_${event.reciterName}',
    );

    final Either<Failure, void> result = await _downloadSurah(
      surahId: event.surahId,
      surahTitle: event.surahTitle,
      reciterName: event.reciterName,
    );

    result.fold(
      (failure) {
        // Log analytics event for download failure
        _analyticsService.logEvent(
          'download_failed',
          parameters: {
            'download_id': analyticsDownloadId,
            'surah_id': event.surahId,
            'reciter_name': event.reciterName,
            'error': failure.message ?? 'Unknown error',
          },
        );
        emit(
          DownloadsState.error(failure.message ?? 'Failed to download surah'),
        );
      },
      (_) {
        // Log analytics event for download completion
        _analyticsService.logDownloadComplete(
          analyticsDownloadId,
          fileName: '${event.surahTitle}_${event.reciterName}',
        );
        // Reload downloads after successful download
        add(const LoadDownloads());
      },
    );
  }

  Future<void> _onDeleteDownload(
    DeleteDownloadEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    final Either<Failure, void> result = await _deleteDownload(
      event.downloadId,
    );
    result.fold(
      (failure) => emit(
        DownloadsState.error(failure.message ?? 'Failed to delete download'),
      ),
      (_) {
        // Reload downloads after successful deletion
        add(const LoadDownloads());
      },
    );
  }

  Future<void> _onDeleteReciterDownloads(
    DeleteReciterDownloads event,
    Emitter<DownloadsState> emit,
  ) async {
    final Either<Failure, void> result = await _deleteReciterDownloads(
      event.reciterName,
    );
    result.fold(
      (failure) => emit(
        DownloadsState.error(
          failure.message ?? 'Failed to delete reciter downloads',
        ),
      ),
      (_) {
        // Log analytics event for delete reciter downloads
        _analyticsService.logEvent(
          'delete_reciter_downloads',
          parameters: {
            'reciter_name': event.reciterName,
            'action': 'delete_reciter_downloads',
          },
        );
        // Reload downloads after successful deletion
        add(const LoadDownloads());
      },
    );
  }

  Future<void> _onClearAllDownloads(
    ClearAllDownloads event,
    Emitter<DownloadsState> emit,
  ) async {
    final Either<Failure, void> result = await _clearAllDownloads();
    result.fold(
      (failure) => emit(
        DownloadsState.error(
          failure.message ?? 'Failed to clear all downloads',
        ),
      ),
      (_) {
        // Log analytics event for clear all downloads
        _analyticsService.logEvent(
          'clear_all_downloads',
          parameters: {'action': 'clear_all_downloads'},
        );
        // Reload downloads after successful clearing
        add(const LoadDownloads());
      },
    );
  }

  Future<void> _onCheckSurahDownloaded(
    CheckSurahDownloadedEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    try {
      final bool isDownloaded = await _downloadsRepository.isSurahDownloaded(
        event.surahId,
        event.reciterName,
      );
      emit(
        DownloadsState.surahDownloadStatus(
          surahId: event.surahId,
          reciterName: event.reciterName,
          isDownloaded: isDownloaded,
        ),
      );
    } catch (e) {
      emit(DownloadsState.error('Failed to check download status: $e'));
    }
  }

  Future<void> _onValidateDownloadedFile(
    ValidateDownloadedFileEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    try {
      final DownloadItem? download = await _downloadsRepository.getDownloadItem(
        event.downloadId,
      );
      if (download == null) {
        emit(const DownloadsState.error('Download not found'));
        return;
      }

      final bool isValid = await _downloadsRepository.validateDownloadedFile(
        download,
      );
      emit(
        DownloadsState.fileValidationResult(
          downloadId: event.downloadId,
          isValid: isValid,
        ),
      );
    } catch (e) {
      emit(DownloadsState.error('Failed to validate file: $e'));
    }
  }

  Future<void> _onGetValidCompletedDownloads(
    GetValidCompletedDownloadsEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    try {
      final List<DownloadItem> validDownloads = await _downloadsRepository
          .getValidCompletedDownloads(event.reciterName);
      emit(
        DownloadsState.validDownloadsLoaded(
          reciterName: event.reciterName,
          validDownloads: validDownloads,
        ),
      );
    } catch (e) {
      emit(DownloadsState.error('Failed to get valid downloads: $e'));
    }
  }

  Future<void> _onPlayDownloadedSurah(
    PlayDownloadedSurahEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    try {
      final DownloadItem? download = await _downloadsRepository.getDownloadItem(
        event.downloadId,
      );
      if (download == null) {
        emit(const DownloadsState.error('Download not found'));
        return;
      }

      // Validate file exists
      final bool fileExists = await _downloadsRepository.validateDownloadedFile(
        download,
      );
      if (!fileExists) {
        emit(const DownloadsState.error('Downloaded file not found'));
        return;
      }

      // Create MediaItem and play
      final MediaItem mediaItem = _downloadsRepository
          .createMediaItemFromDownload(download);

      await _audioPlayerHandler.updateQueue([mediaItem]);
      await _audioPlayerHandler.pause();
      await _audioPlayerHandler.skipToQueueItem(0);
      await _audioPlayerHandler.play();

      emit(
        DownloadsState.playbackInitiated(
          message: 'Playing ${download.title}',
          downloadsByReciter: _getCurrentDownloads(),
        ),
      );
    } catch (e) {
      emit(DownloadsState.error('Error playing surah: $e'));
    }
  }

  Future<void> _onPlayAllDownloads(
    PlayAllDownloadsEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    try {
      final List<DownloadItem> validDownloads = await _downloadsRepository
          .getValidCompletedDownloads(event.reciterName);

      if (validDownloads.isEmpty) {
        emit(const DownloadsState.error('No valid downloaded files found'));
        return;
      }

      // Create MediaItems and play
      final List<MediaItem> mediaItems = _downloadsRepository
          .createMediaItemsFromDownloads(validDownloads);

      await _audioPlayerHandler.updateQueue(mediaItems);
      await _audioPlayerHandler.pause();
      await _audioPlayerHandler.skipToQueueItem(0);
      await _audioPlayerHandler.play();

      emit(
        DownloadsState.playbackInitiated(
          message:
              'Playing ${validDownloads.length} surahs from ${event.reciterName}',
          downloadsByReciter: _getCurrentDownloads(),
        ),
      );
    } catch (e) {
      emit(DownloadsState.error('Error playing downloads: $e'));
    }
  }

  Future<void> _onCheckPremiumAccess(
    CheckPremiumAccessEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    try {
      final bool canDownload = await _premiumRepository.canDownload();
      if (!canDownload) {
        emit(
          DownloadsState.premiumRequired(
            message:
                'Download feature requires premium subscription. Upgrade to unlock unlimited downloads!',
            downloadsByReciter: _getCurrentDownloads(),
          ),
        );
      }
    } catch (e) {
      emit(DownloadsState.error('Failed to check premium access: $e'));
    }
  }

  Future<void> _onRetryDownload(
    RetryDownloadEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    try {
      // Get the failed download item
      final DownloadItem? downloadItem = await _downloadsRepository
          .getDownloadItem(event.downloadId);
      if (downloadItem == null) {
        emit(const DownloadsState.error('Download not found'));
        return;
      }

      // Check if download is stuck (at 0% for more than 30 seconds)
      final Duration timeSinceCreated = DateTime.now().difference(
        downloadItem.createdAt,
      );
      final bool isStuck =
          downloadItem.status == DownloadStatus.downloading &&
          downloadItem.progress == 0.0 &&
          timeSinceCreated.inSeconds > 30;

      // Allow retry for failed downloads or stuck downloads
      if (downloadItem.status != DownloadStatus.failed && !isStuck) {
        emit(
          const DownloadsState.error(
            'Only failed or stuck downloads can be retried',
          ),
        );
        return;
      }

      // Check premium access before allowing retry
      final bool canDownload = await _premiumRepository.canDownload();
      if (!canDownload) {
        emit(
          DownloadsState.premiumRequired(
            message:
                'Download feature requires premium subscription. Upgrade to unlock unlimited downloads!',
            downloadsByReciter: _getCurrentDownloads(),
          ),
        );
        return;
      }

      // Check if download is currently in progress
      try {
        if (await DownloadService.isDownloadActive(event.downloadId)) {
          emit(
            DownloadsState.error(
              'Download "${downloadItem.title}" is already being downloaded',
            ),
          );
          return;
        }
      } on MissingPluginException {
        // In test environment, platform channels are not available
        // Skip the check and continue with retry
        logger.d(
          '[DownloadsBloc] DownloadService.isDownloadActive skipped - platform channels not available (test environment)',
        );
      } catch (e) {
        // Any other error - log and continue
        logger.w('[DownloadsBloc] Error checking if download is active: $e');
      }

      // Emit download started state
      emit(
        DownloadsState.downloadStarted(
          surahId: downloadItem.id.split('_')[0],
          surahTitle: downloadItem.title,
          reciterName: downloadItem.reciterName,
          downloadsByReciter: _getCurrentDownloads(),
        ),
      );

      // Log analytics event for retry
      await _analyticsService.logEvent(
        'download_retry',
        parameters: {
          'download_id': event.downloadId,
          'surah_title': downloadItem.title,
          'reciter_name': downloadItem.reciterName,
        },
      );

      // Retry the download using the repository method
      try {
        await _downloadsRepository.retryDownload(event.downloadId);

        // Log analytics event for retry success
        await _analyticsService.logEvent(
          'download_retry_success',
          parameters: {
            'download_id': event.downloadId,
            'surah_title': downloadItem.title,
            'reciter_name': downloadItem.reciterName,
          },
        );
        // Reload downloads after successful retry
        add(const LoadDownloads());
      } catch (e) {
        // Log analytics event for retry failure
        await _analyticsService.logEvent(
          'download_retry_failed',
          parameters: {
            'download_id': event.downloadId,
            'surah_title': downloadItem.title,
            'reciter_name': downloadItem.reciterName,
            'error': e.toString(),
          },
        );
        emit(DownloadsState.error('Failed to retry download: $e'));
      }
    } catch (e) {
      emit(DownloadsState.error('Failed to retry download: $e'));
    }
  }

  @override
  DownloadsState? fromJson(Map<String, dynamic> json) {
    // Downloads should be loaded from database, so we always start with initial state
    return const DownloadsState.initial();
  }

  @override
  Map<String, dynamic>? toJson(DownloadsState state) {
    // Only persist if in initial state to avoid storing complex download data
    if (state is DownloadsInitial) {
      return {'state': 'initial'};
    }
    // For other states, don't persist (will reload from database)
    return null;
  }
}
