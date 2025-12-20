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
import '../../../../core/usecases/usecase.dart';
import '../../../../main.dart';
import '../../../../shared/audio/audio_player_handler.dart';
import '../../../premium/domain/repositories/premium_repository.dart';
import '../../data/services/download_queue_manager.dart';
import '../../data/services/download_service.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/repositories/downloads_repository.dart';
import '../../domain/usecases/clear_all_downloads_use_case.dart';
import '../../domain/usecases/delete_download_use_case.dart';
import '../../domain/usecases/delete_reciter_downloads_use_case.dart';
import '../../domain/usecases/download_surah_use_case.dart';
import '../../domain/usecases/get_downloads_by_reciter_use_case.dart';
import '../../domain/usecases/get_total_downloads_size_use_case.dart';
import 'downloads_status.dart';

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
    required GetTotalDownloadsSizeUseCase getTotalDownloadsSize,
    required DownloadsRepository downloadsRepository,
    required PremiumRepository premiumRepository,
    required AudioPlayerHandler audioPlayerHandler,
    required AnalyticsService analyticsService,
  }) : _getDownloadsByReciter = getDownloadsByReciter,
       _downloadSurah = downloadSurah,
       _deleteDownload = deleteDownload,
       _deleteReciterDownloads = deleteReciterDownloads,
       _clearAllDownloads = clearAllDownloads,
       _getTotalDownloadsSize = getTotalDownloadsSize,
       _downloadsRepository = downloadsRepository,
       _premiumRepository = premiumRepository,
       _audioPlayerHandler = audioPlayerHandler,
       _analyticsService = analyticsService,
       super(const DownloadsState()) {
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

    // Progress listening is now handled by DownloadButtonBloc for individual items
    // DownloadsBloc only needs to refresh the list when a download completes/adds/removes
    _listenToGlobalProgress();
  }
  final GetDownloadsByReciterUseCase _getDownloadsByReciter;
  final DownloadSurahUseCase _downloadSurah;
  final DeleteDownloadUseCase _deleteDownload;
  final DeleteReciterDownloadsUseCase _deleteReciterDownloads;
  final ClearAllDownloadsUseCase _clearAllDownloads;
  final GetTotalDownloadsSizeUseCase _getTotalDownloadsSize;
  final DownloadsRepository _downloadsRepository;
  final PremiumRepository _premiumRepository;
  final AudioPlayerHandler _audioPlayerHandler;
  final AnalyticsService _analyticsService;

  StreamSubscription<DownloadProgress>? _progressSubscription;

  // Broadcast stream controller for one-time status events
  // This allows UI to react to events without changing the main state
  final StreamController<DownloadsStatus> _statusController =
      StreamController<DownloadsStatus>.broadcast();

  /// Exposes a broadcast stream of status events
  Stream<DownloadsStatus> get statusStream => _statusController.stream;

  /// Listens to global download progress updates to refresh the list when necessary.
  ///
  /// This replaces the granular progress tracking. We only care about
  /// refreshing the list when a download starts or completes, as the list view
  /// shows the existence of downloads, not their real-time progress.
  void _listenToGlobalProgress() {
    try {
      _progressSubscription?.cancel();
      _progressSubscription = DownloadService.instance.globalProgressStream
          .listen(
            _handleGlobalProgressUpdate,
            onError: (e) =>
                logger.e('[DownloadsBloc] Progress stream error: $e'),
            cancelOnError: false,
          );
      logger.d('[DownloadsBloc] Global progress listener initialized');
    } catch (e) {
      // Ignore errors in test environment or setup failure
    }
  }

  /// Handles global progress updates to trigger list refreshes on state changes
  void _handleGlobalProgressUpdate(DownloadProgress progress) {
    // We only need to reload the list if the status implies a change in the
    // "Have downloads" state or if a new download started/completed.
    // Real-time progress is handled by DownloadButtonBloc.

    // Reload on terminal states to ensure list is up to date
    if (_isTerminalStatus(progress.status)) {
      add(const LoadDownloads());
    }
  }

  /// Checks if a download status is terminal (no more updates expected).
  bool _isTerminalStatus(DownloadStatus status) {
    return status == DownloadStatus.completed ||
        status == DownloadStatus.failed ||
        status == DownloadStatus.cancelled;
  }

  @override
  Future<void> close() async {
    await _progressSubscription?.cancel();
    await _statusController.close();
    return super.close();
  }

  Future<void> _onLoadDownloads(
    LoadDownloads event,
    Emitter<DownloadsState> emit,
  ) async {
    emit(state.copyWith(status: DownloadsStateStatus.loading));
    final Either<Failure, Map<String, Map<String, List<DownloadItem>>>> result =
        await _getDownloadsByReciter();
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: DownloadsStateStatus.error,
          errorMessage: failure.message ?? 'Failed to load downloads',
        ),
      ),
      (downloads) async {
        // Also fetch total size
        final Either<Failure, int> sizeResult = await _getTotalDownloadsSize(
          const NoParams(),
        );

        emit(
          state.copyWith(
            status: DownloadsStateStatus.loaded,
            downloads: downloads,
            totalDownloadsSize: sizeResult.getOrElse(() => 0),
            errorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> _onDownloadSurah(
    DownloadSurahEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    // Check premium access before allowing download
    final bool canDownload = await _premiumRepository.canDownload();
    if (!canDownload) {
      if (!_statusController.isClosed) {
        _statusController.add(
          const DownloadsStatus.premiumRequired(
            message:
                'Download feature requires premium subscription. Upgrade to unlock unlimited downloads!',
          ),
        );
      }
      return;
    }

    // Check if surah is already downloaded
    final bool isAlreadyDownloaded = await _downloadsRepository
        .isSurahDownloaded(event.surahId, event.reciterName);

    // Capture current downloads before potential state change

    if (isAlreadyDownloaded) {
      if (!_statusController.isClosed) {
        _statusController.add(
          DownloadsStatus.error(
            message:
                'Surah "${event.surahTitle}" by ${event.reciterName} is already downloaded',
          ),
        );
      }
      return;
    }

    // Check if download is currently in progress
    // Note: surahId is the URL, and DownloadService uses URL as the task ID
    try {
      if (await DownloadService.isDownloadActive(event.surahId)) {
        if (!_statusController.isClosed) {
          _statusController.add(
            DownloadsStatus.error(
              message:
                  'Surah "${event.surahTitle}" by ${event.reciterName} is already being downloaded',
            ),
          );
        }
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
      reciterId: event.reciterId,
      status: DownloadStatus.downloading,
      progress: 0.0,
      downloadedSize: 0,
      fileSize: 0,
      filePath: '',
      createdAt: DateTime.now(),
    );

    // Emit download started state
    // Emit download started status
    if (!_statusController.isClosed) {
      _statusController.add(
        DownloadsStatus.downloadStarted(
          surahId: downloadItem.id.split(
            '_',
          )[0], // Extract surah ID from download ID
          surahTitle: downloadItem.title,
          reciterName: downloadItem.reciterName,
        ),
      );
    }

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
      reciterId: event.reciterId,
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
        if (!_statusController.isClosed) {
          _statusController.add(
            DownloadsStatus.error(
              message: failure.message ?? 'Failed to download surah',
            ),
          );
        }
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
    // Cancel the download if it's active in the queue
    try {
      final DownloadStatus? status = await DownloadService.getDownloadStatus(
        event.downloadId,
      );

      // Only cancel if it's actually running or pending
      // Cancelling a completed download might trigger a 'cancelled' event
      // which could revive the download in the db
      if (status == DownloadStatus.downloading ||
          status == DownloadStatus.pending ||
          status == DownloadStatus.paused) {
        await DownloadService.cancelDownload(event.downloadId);
      }
    } on MissingPluginException {
      // In test environment, platform channels are not available
      logger.d(
        '[DownloadsBloc] DownloadService.cancelDownload skipped - platform channels not available',
      );
    } catch (e) {
      logger.w('[DownloadsBloc] Error cancelling download before deletion: $e');
    }

    // Also remove from the pending queue if present
    DownloadQueueManager.instance.removeFromQueue(event.downloadId);

    final Either<Failure, void> result = await _deleteDownload(
      event.downloadId,
    );
    result.fold(
      (failure) {
        if (!_statusController.isClosed) {
          _statusController.add(
            DownloadsStatus.error(
              message: failure.message ?? 'Failed to delete download',
            ),
          );
        }
      },
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
    // Cancel all active downloads for this reciter before deleting
    try {
      final Map<String, List<DownloadItem>>? reciterNarratives =
          state.downloads[event.reciterName];
      if (reciterNarratives != null) {
        for (final List<DownloadItem> downloads in reciterNarratives.values) {
          for (final download in downloads) {
            if (download.status == DownloadStatus.downloading ||
                download.status == DownloadStatus.pending) {
              await DownloadService.cancelDownload(download.url);
            }
            // Also remove from the pending queue
            DownloadQueueManager.instance.removeFromQueue(download.id);
          }
        }
      }
    } on MissingPluginException {
      logger.d(
        '[DownloadsBloc] DownloadService.cancelDownload skipped - platform channels not available',
      );
    } catch (e) {
      logger.w(
        '[DownloadsBloc] Error cancelling downloads before deletion: $e',
      );
    }

    final Either<Failure, void> result = await _deleteReciterDownloads(
      event.reciterName,
    );
    result.fold(
      (failure) {
        if (!_statusController.isClosed) {
          _statusController.add(
            DownloadsStatus.error(
              message: failure.message ?? 'Failed to delete reciter downloads',
            ),
          );
        }
      },
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
    // Cancel all active downloads before clearing
    try {
      for (final Map<String, List<DownloadItem>> reciterDownloads
          in state.downloads.values) {
        for (final List<DownloadItem> downloads in reciterDownloads.values) {
          for (final download in downloads) {
            if (download.status == DownloadStatus.downloading ||
                download.status == DownloadStatus.pending) {
              await DownloadService.cancelDownload(download.url);
            }
          }
        }
      }
      // Clear the entire pending queue
      DownloadQueueManager.instance.clearQueue();
    } on MissingPluginException {
      logger.d(
        '[DownloadsBloc] DownloadService.cancelDownload skipped - platform channels not available',
      );
    } catch (e) {
      logger.w(
        '[DownloadsBloc] Error cancelling downloads before clearing: $e',
      );
    }

    final Either<Failure, void> result = await _clearAllDownloads();
    result.fold(
      (failure) {
        if (!_statusController.isClosed) {
          _statusController.add(
            DownloadsStatus.error(
              message: failure.message ?? 'Failed to clear all downloads',
            ),
          );
        }
      },
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
      if (!_statusController.isClosed) {
        _statusController.add(
          DownloadsStatus.surahDownloadStatus(
            surahId: event.surahId,
            reciterName: event.reciterName,
            isDownloaded: isDownloaded,
          ),
        );
      }
    } catch (e) {
      if (!_statusController.isClosed) {
        _statusController.add(
          DownloadsStatus.error(message: 'Failed to check download status: $e'),
        );
      }
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
        emit(
          state.copyWith(
            status: DownloadsStateStatus.error,
            errorMessage: 'Download not found',
          ),
        );
        return;
      }

      final bool isValid = await _downloadsRepository.validateDownloadedFile(
        download,
      );
      if (!_statusController.isClosed) {
        _statusController.add(
          DownloadsStatus.fileValidationResult(
            downloadId: event.downloadId,
            isValid: isValid,
          ),
        );
      }
    } catch (e) {
      if (!_statusController.isClosed) {
        _statusController.add(
          DownloadsStatus.error(message: 'Failed to validate file: $e'),
        );
      }
    }
  }

  Future<void> _onGetValidCompletedDownloads(
    GetValidCompletedDownloadsEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    try {
      final List<DownloadItem> validDownloads = await _downloadsRepository
          .getValidCompletedDownloads(event.reciterName);
      if (!_statusController.isClosed) {
        _statusController.add(
          DownloadsStatus.validDownloadsLoaded(
            reciterName: event.reciterName,
            validDownloads: validDownloads,
          ),
        );
      }
    } catch (e) {
      if (!_statusController.isClosed) {
        _statusController.add(
          DownloadsStatus.error(message: 'Failed to get valid downloads: $e'),
        );
      }
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
        if (!_statusController.isClosed) {
          _statusController.add(
            const DownloadsStatus.error(message: 'Download not found'),
          );
        }
        return;
      }

      // Validate file exists
      final bool fileExists = await _downloadsRepository.validateDownloadedFile(
        download,
      );
      if (!fileExists) {
        if (!_statusController.isClosed) {
          _statusController.add(
            const DownloadsStatus.error(message: 'Downloaded file not found'),
          );
        }
        return;
      }

      // Create MediaItem and play
      final MediaItem mediaItem = _downloadsRepository
          .createMediaItemFromDownload(download);

      await _audioPlayerHandler.updateQueue([mediaItem]);
      await _audioPlayerHandler.pause();
      await _audioPlayerHandler.skipToQueueItem(0);
      await _audioPlayerHandler.play();

      if (!_statusController.isClosed) {
        _statusController.add(
          DownloadsStatus.playbackInitiated(
            message: 'Playing ${download.title}',
          ),
        );
      }
    } catch (e) {
      if (!_statusController.isClosed) {
        _statusController.add(
          DownloadsStatus.error(message: 'Error playing surah: $e'),
        );
      }
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
        if (!_statusController.isClosed) {
          _statusController.add(
            const DownloadsStatus.error(
              message: 'No valid downloaded files found',
            ),
          );
        }
        return;
      }

      // Create MediaItems and play
      final List<MediaItem> mediaItems = _downloadsRepository
          .createMediaItemsFromDownloads(validDownloads);

      await _audioPlayerHandler.updateQueue(mediaItems);
      await _audioPlayerHandler.pause();
      await _audioPlayerHandler.skipToQueueItem(0);
      await _audioPlayerHandler.play();

      if (!_statusController.isClosed) {
        _statusController.add(
          DownloadsStatus.playbackInitiated(
            message:
                'Playing ${validDownloads.length} surahs from ${event.reciterName}',
          ),
        );
      }
    } catch (e) {
      if (!_statusController.isClosed) {
        _statusController.add(
          DownloadsStatus.error(message: 'Error playing downloads: $e'),
        );
      }
    }
  }

  Future<void> _onCheckPremiumAccess(
    CheckPremiumAccessEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    try {
      final bool canDownload = await _premiumRepository.canDownload();
      if (!canDownload) {
        if (!_statusController.isClosed) {
          _statusController.add(
            const DownloadsStatus.premiumRequired(
              message:
                  'Download feature requires premium subscription. Upgrade to unlock unlimited downloads!',
            ),
          );
        }
      }
    } catch (e) {
      if (!_statusController.isClosed) {
        _statusController.add(
          DownloadsStatus.error(message: 'Failed to check premium access: $e'),
        );
      }
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
        if (!_statusController.isClosed) {
          _statusController.add(
            const DownloadsStatus.error(message: 'Download not found'),
          );
        }
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
        if (!_statusController.isClosed) {
          _statusController.add(
            const DownloadsStatus.error(
              message: 'Only failed or stuck downloads can be retried',
            ),
          );
        }
        return;
      }

      // Check premium access before allowing retry
      final bool canDownload = await _premiumRepository.canDownload();
      if (!canDownload) {
        if (!_statusController.isClosed) {
          _statusController.add(
            const DownloadsStatus.premiumRequired(
              message:
                  'Download feature requires premium subscription. Upgrade to unlock unlimited downloads!',
            ),
          );
        }
        return;
      }

      // Check if download is currently in progress
      try {
        if (await DownloadService.isDownloadActive(event.downloadId)) {
          if (!_statusController.isClosed) {
            _statusController.add(
              DownloadsStatus.error(
                message:
                    'Download "${downloadItem.title}" is already being downloaded',
              ),
            );
          }
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
      if (!_statusController.isClosed) {
        _statusController.add(
          DownloadsStatus.downloadStarted(
            surahId: downloadItem.id.split('_')[0],
            surahTitle: downloadItem.title,
            reciterName: downloadItem.reciterName,
          ),
        );
      }

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
        if (!_statusController.isClosed) {
          _statusController.add(
            DownloadsStatus.error(message: 'Failed to retry download: $e'),
          );
        }
      }
    } catch (e) {
      if (!_statusController.isClosed) {
        _statusController.add(
          DownloadsStatus.error(message: 'Failed to retry download: $e'),
        );
      }
    }
  }

  Future<void> _onRefreshDownloadsProgress(
    RefreshDownloadsProgress event,
    Emitter<DownloadsState> emit,
  ) async {
    // Only refresh if we're already in loaded state
    // This prevents refreshing during initial load or error states
    if (state.status != DownloadsStateStatus.loaded) {
      return;
    }

    final Either<Failure, Map<String, Map<String, List<DownloadItem>>>> result =
        await _getDownloadsByReciter();
    await result.fold(
      (failure) async {
        // On error, keep the current state but don't show error
        // This is a background refresh, so we don't want to disrupt the UI
        logger.w(
          '[DownloadsBloc] Failed to refresh downloads: ${failure.message}',
        );
      },
      (downloads) async {
        // Also fetch total size
        final Either<Failure, int> sizeResult = await _getTotalDownloadsSize(
          const NoParams(),
        );

        // Emit directly to loaded state without showing loading state
        emit(
          state.copyWith(
            status: DownloadsStateStatus.loaded,
            downloads: downloads,
            totalDownloadsSize: sizeResult.getOrElse(() => 0),
            errorMessage: null,
          ),
        );
      },
    );
  }

  @override
  DownloadsState? fromJson(Map<String, dynamic> json) {
    // Downloads should be loaded from database, so we always start with initial state
    return const DownloadsState();
  }

  @override
  Map<String, dynamic>? toJson(DownloadsState state) {
    // Only persist if in initial state to avoid storing complex download data
    if (state.status == DownloadsStateStatus.initial) {
      return {'state': 'initial'};
    }
    // For other states, don't persist (will reload from database)
    return null;
  }
}
