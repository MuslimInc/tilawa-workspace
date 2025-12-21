import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../main.dart';
import '../../../data/services/download_service.dart';
import '../../../domain/entities/download_item.dart';
import '../../../domain/repositories/downloads_repository.dart';

part 'download_button_bloc.freezed.dart';
part 'download_button_event.dart';
part 'download_button_state.dart';

/// BLoC for managing individual download button state
///
/// This BLoC is lightweight and focused on a SINGLE download.
/// Benefits:
/// - No unnecessary rebuilds from unrelated downloads
/// - Clear separation of concerns
/// - Easy to test in isolation
/// - Scales well (can have 100+ buttons without performance issues)

class DownloadButtonBloc
    extends Bloc<DownloadButtonEvent, DownloadButtonState> {
  DownloadButtonBloc({
    required String url,
    required String reciterName,
    required int reciterId,
    required DownloadsRepository downloadsRepository,
    this.initialIsDownloaded,
    this.initialIsDownloading,
    this.initialProgress,
  }) : _url = url.trim(),
       _reciterName = reciterName,
       _reciterId = reciterId,
       _downloadsRepository = downloadsRepository,
       super(const DownloadButtonState.initial()) {
    on<DownloadButtonEvent>((event, emit) async {
      // Use map instead of when for event handling
      await event.map(
        initialize: (_) async => _onInitialize(emit),
        startDownload: (e) async => _onStartDownload(e.surahTitle, emit),
        retry: (e) async => _onRetry(e.surahTitle, emit),
        cancel: (_) async => _onCancel(emit),
        progressUpdated: (e) async => _onProgressUpdated(
          e.progress,
          e.downloadedBytes,
          e.totalBytes,
          emit,
        ),
        completed: (_) async => _onCompleted(emit),
        failed: (e) async => _onFailed(e.errorMessage, emit),
        cancelled: (_) async => _onCancelled(emit),
        paused: (_) async => _onPaused(emit),
      );
    });
  }

  final String _url;
  final String _reciterName;
  final int _reciterId;
  final DownloadsRepository _downloadsRepository;
  final bool? initialIsDownloaded;
  final bool? initialIsDownloading;
  final double? initialProgress;
  StreamSubscription<DownloadProgress>? _progressSubscription;
  StreamSubscription<DownloadItem>? _updatesSubscription;
  bool _isFirstInit = true; // Track if this is the first initialization

  /// Initialize button state by checking current download status
  Future<void> _onInitialize(Emitter<DownloadButtonState> emit) async {
    // Ensure we are listening to repository updates for batch operations
    _updatesSubscription ??= _downloadsRepository.downloadUpdates.listen((
      item,
    ) {
      if (item.url == _url && item.reciterName == _reciterName) {
        add(const DownloadButtonEvent.initialize());
      }
    });

    try {
      // optimization: Use initial state ONLY on first initialization
      // After that, always query the actual state to ensure we sync with repository updates
      if (_isFirstInit) {
        _isFirstInit = false; // Mark that we've initialized once

        if (initialIsDownloaded ?? false) {
          emit(const DownloadButtonState.completed());
          return;
        }

        if (initialIsDownloading ?? false) {
          _listenToProgress();
          emit(
            DownloadButtonState.downloading(progress: initialProgress ?? 0.0),
          );
          return;
        }

        // If explicit FALSE was provided, we might still want to check just to be safe?
        // Or trust the caller. If caller says false, it's false.
        // But typically caller passes null if unknown.
        if (initialIsDownloaded == false && initialIsDownloading == false) {
          emit(const DownloadButtonState.readyToDownload());
          return;
        }
      }

      // On subsequent initializations OR if no initial values provided,
      // always check actual state from database/service
      // Check if already downloaded
      final bool isDownloaded = await _downloadsRepository.isSurahDownloaded(
        _url,
        _reciterName,
      );

      if (isDownloaded) {
        emit(const DownloadButtonState.completed());
        return;
      }

      // Check if currently downloading
      final bool isDownloading = await _downloadsRepository.isSurahDownloading(
        _url,
        _reciterName,
      );

      if (isDownloading) {
        _listenToProgress();
        // Get current download item to get progress
        final DownloadItem? downloadItem = await _downloadsRepository
            .getDownloadItem(_url);

        if (downloadItem != null) {
          switch (downloadItem.status) {
            case DownloadStatus.pending:
              emit(const DownloadButtonState.pending());
            case DownloadStatus.downloading:
              emit(
                DownloadButtonState.downloading(
                  progress: downloadItem.progress,
                  downloadedBytes: downloadItem.downloadedSize,
                  totalBytes: downloadItem.fileSize,
                ),
              );
            case DownloadStatus.completed:
              emit(const DownloadButtonState.completed());
            case DownloadStatus.failed:
              emit(const DownloadButtonState.failed());
            case DownloadStatus.cancelled:
              emit(const DownloadButtonState.cancelled());
            case DownloadStatus.paused:
              emit(const DownloadButtonState.paused());
          }
        } else {
          // If item is actively downloading in service but not yet found in DB with this ID,
          // assume it's starting and show pending or 0%
          emit(const DownloadButtonState.downloading(progress: 0.0));
        }
        return;
      }

      // Default: ready to download
      emit(const DownloadButtonState.readyToDownload());
    } on MissingPluginException catch (e) {
      // In test environment, platform channels are not available
      logger.d(
        '[DownloadButtonBloc] Initialize skipped - platform channels not available: $e',
      );
      emit(const DownloadButtonState.readyToDownload());
    } catch (e, stackTrace) {
      logger.e(
        '[DownloadButtonBloc] Error initializing',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        const DownloadButtonState.failed(
          errorMessage: 'Failed to check download status',
        ),
      );
    }
  }

  /// Start download process
  Future<void> _onStartDownload(
    String surahTitle,
    Emitter<DownloadButtonState> emit,
  ) async {
    try {
      emit(const DownloadButtonState.pending());

      // Listen to progress before starting download
      _listenToProgress();

      // Note: We don't await this - it will trigger progress updates
      // The actual download state changes will come through the progress stream
      await _downloadsRepository.startDownload(
        _url,
        title: surahTitle,
        reciterName: _reciterName,
        reciterId: _reciterId,
        surahTitle: surahTitle,
      );

      logger.d(
        '[DownloadButtonBloc] Download started: url=$_url reciter=$_reciterName',
      );
    } on MissingPluginException catch (e) {
      logger.d(
        '[DownloadButtonBloc] Download start skipped - platform channels not available: $e',
      );
      // In test environment, just stay in pending state
    } catch (e, stackTrace) {
      logger.e(
        '[DownloadButtonBloc] Error starting download',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        DownloadButtonState.failed(
          errorMessage: 'Failed to start download: $e',
        ),
      );
    }
  }

  /// Retry a failed download
  Future<void> _onRetry(
    String surahTitle,
    Emitter<DownloadButtonState> emit,
  ) async {
    // Same as starting download
    add(DownloadButtonEvent.startDownload(surahTitle: surahTitle));
  }

  /// Cancel active download
  Future<void> _onCancel(Emitter<DownloadButtonState> emit) async {
    try {
      // We use the URL as ID mostly, but repo expects ID.
      // For now, let's assume usage of URL as ID is consistent.
      await _downloadsRepository.cancelDownload(_url);
      await _progressSubscription?.cancel();
      emit(const DownloadButtonState.cancelled());
      logger.d('[DownloadButtonBloc] Download cancelled: url=$_url');
    } on MissingPluginException catch (e) {
      logger.d(
        '[DownloadButtonBloc] Cancel skipped - platform channels not available: $e',
      );
      emit(const DownloadButtonState.cancelled());
    } catch (e, stackTrace) {
      logger.e(
        '[DownloadButtonBloc] Error cancelling download',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        const DownloadButtonState.failed(
          errorMessage: 'Failed to cancel download',
        ),
      );
    }
  }

  /// Handle progress update
  void _onProgressUpdated(
    double progress,
    int downloadedBytes,
    int totalBytes,
    Emitter<DownloadButtonState> emit,
  ) {
    emit(
      DownloadButtonState.downloading(
        progress: progress,
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
      ),
    );
  }

  /// Handle completion
  void _onCompleted(Emitter<DownloadButtonState> emit) {
    _progressSubscription?.cancel();
    emit(const DownloadButtonState.completed());
    logger.d('[DownloadButtonBloc] Download completed: url=$_url');
  }

  /// Handle failure
  void _onFailed(String? errorMessage, Emitter<DownloadButtonState> emit) {
    _progressSubscription?.cancel();
    emit(DownloadButtonState.failed(errorMessage: errorMessage));
    logger.w(
      '[DownloadButtonBloc] Download failed: url=$_url error=$errorMessage',
    );
  }

  /// Handle cancellation
  void _onCancelled(Emitter<DownloadButtonState> emit) {
    _progressSubscription?.cancel();
    emit(const DownloadButtonState.cancelled());
  }

  /// Handle pause
  void _onPaused(Emitter<DownloadButtonState> emit) {
    _progressSubscription?.cancel();
    emit(const DownloadButtonState.paused());
  }

  /// Listen to progress updates for this specific download
  void _listenToProgress() {
    try {
      _progressSubscription?.cancel();

      _progressSubscription = DownloadService.instance
          .getProgressStream(_url)
          .listen(
            (progress) {
              switch (progress.status) {
                case DownloadStatus.pending:
                  // Pending is handled by initialization/start, but if we get explicit pending event, good to verify
                  // For now, ignore to avoid flickering
                  break;
                case DownloadStatus.downloading:
                  add(
                    DownloadButtonEvent.progressUpdated(
                      progress: progress.progress,
                      downloadedBytes: progress.downloadedSize,
                      totalBytes: progress.fileSize,
                    ),
                  );
                case DownloadStatus.completed:
                  add(const DownloadButtonEvent.completed());
                case DownloadStatus.failed:
                  add(
                    const DownloadButtonEvent.failed(
                      errorMessage: 'Download failed',
                    ),
                  );
                case DownloadStatus.cancelled:
                  add(const DownloadButtonEvent.cancelled());
                case DownloadStatus.paused:
                  add(const DownloadButtonEvent.paused());
              }
            },
            onError: (error, stackTrace) {
              logger.e(
                '[DownloadButtonBloc] Progress stream error',
                error: error,
                stackTrace: stackTrace,
              );
              add(
                DownloadButtonEvent.failed(
                  errorMessage: 'Download error: $error',
                ),
              );
            },
            cancelOnError: false,
          );

      logger.d('[DownloadButtonBloc] Started listening to progress for $_url');
    } on MissingPluginException catch (e) {
      logger.d(
        '[DownloadButtonBloc] Progress listening skipped - platform channels not available: $e',
      );
    } catch (e, stackTrace) {
      logger.e(
        '[DownloadButtonBloc] Error setting up progress listener',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    _updatesSubscription?.cancel();
    return super.close();
  }
}
