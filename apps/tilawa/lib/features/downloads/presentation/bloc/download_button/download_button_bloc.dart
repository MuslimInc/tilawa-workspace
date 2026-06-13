import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/network/network_info.dart';

import '../../../domain/constants/download_storage_estimates.dart';
import '../../../domain/entities/download_item.dart';
import '../../../domain/usecases/usecases.dart';

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
    required this._reciterName,
    required this._reciterId,
    required this._checkSurahDownloaded,
    required this._downloadSurah,
    required this._cancelDownload,
    required this._pauseDownload,
    required this._resumeDownload,
    required this._observeDownloadProgress,
    required this._getDownloadItem,
    required this._networkInfo,
    required this._checkLowDeviceStorage,
    this._initialIsDownloaded,
    this._initialIsDownloading,
    this._initialProgress,
  }) : _url = url.trim(),
       super(const DownloadButtonState.initial()) {
    on<DownloadButtonEvent>((event, emit) async {
      await event.map(
        initialize: (_) async => _onInitialize(emit),
        startDownload: (e) async => _onStartDownload(e.surahTitle, emit),
        cancel: (_) async => _onCancel(emit),
        requestPause: (_) async => _onRequestPause(emit),
        requestResume: (_) async => _onRequestResume(emit),
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
        pendingDetected: (_) async {
          emit(const DownloadButtonState.pending());
        },
      );
    });
  }

  final String _url;
  final String _reciterName;
  final int _reciterId;
  final CheckSurahDownloadedUseCase _checkSurahDownloaded;
  final DownloadSurahUseCase _downloadSurah;
  final CancelDownloadUseCase _cancelDownload;
  final PauseDownloadUseCase _pauseDownload;
  final ResumeDownloadUseCase _resumeDownload;
  final ObserveDownloadProgressUseCase _observeDownloadProgress;
  final GetDownloadItemUseCase _getDownloadItem;
  final NetworkInfo _networkInfo;
  final CheckLowDeviceStorageUseCase _checkLowDeviceStorage;

  final bool? _initialIsDownloaded;
  final bool? _initialIsDownloading;
  final double? _initialProgress;
  StreamSubscription<DownloadItem>? _progressSubscription;
  DateTime? _lastProgressUpdateTime;

  Future<void> _onInitialize(Emitter<DownloadButtonState> emit) async {
    // 1. If we have explicit initial state, use it immediately
    if (_initialIsDownloaded ?? false) {
      emit(const DownloadButtonState.completed());
      return;
    }

    if (_initialIsDownloading ?? false) {
      emit(DownloadButtonState.downloading(progress: _initialProgress ?? 0.0));
      _listenToProgress();
      return;
    }

    // 2. Otherwise, check the full download status from repository
    // First, get the actual DownloadItem to know the real status
    // (pending, downloading, paused, completed, failed, cancelled)
    final Either<Failure, DownloadItem?> itemResult = await _getDownloadItem(
      _url,
    );
    final DownloadItem? downloadItem = itemResult.getOrElse(() => null);

    if (downloadItem != null) {
      switch (downloadItem.status) {
        case DownloadStatus.completed:
          emit(const DownloadButtonState.completed());
          return;
        case DownloadStatus.downloading:
          emit(
            DownloadButtonState.downloading(
              progress: downloadItem.progress,
              downloadedBytes: downloadItem.downloadedSize,
              totalBytes: downloadItem.fileSize,
            ),
          );
          _listenToProgress();
          return;
        case DownloadStatus.pending:
          emit(const DownloadButtonState.pending());
          _listenToProgress();
          return;
        case DownloadStatus.paused:
          emit(const DownloadButtonState.paused());
          _listenToProgress();
          return;
        case DownloadStatus.failed:
        case DownloadStatus.cancelled:
          // Fall through to readyToDownload
          break;
      }
    } else {
      // No download item found; fall back to legacy check
      final Either<Failure, bool> isDownloadedResult =
          await _checkSurahDownloaded(surahId: _url, reciterName: _reciterName);
      final bool isDownloaded = isDownloadedResult.getOrElse(() => false);

      if (isDownloaded) {
        emit(const DownloadButtonState.completed());
        return;
      }
    }

    // No active or completed download — ready to start fresh
    _listenToProgress();
    emit(const DownloadButtonState.readyToDownload());
  }

  Future<void> _onStartDownload(
    String surahTitle,
    Emitter<DownloadButtonState> emit,
  ) async {
    // Prevent double downloads
    final bool shouldIgnore = state.maybeMap(
      pending: (_) => true,
      downloading: (_) => true,
      orElse: () => false,
    );

    if (shouldIgnore) {
      return;
    }

    if (!await _networkInfo.isConnected) {
      emit(
        const DownloadButtonState.networkError(
          errorMessage: 'No internet connection',
        ),
      );
      return;
    }

    emit(const DownloadButtonState.pending());
    _listenToProgress();

    final bool isStorageLow = await _checkLowDeviceStorage(
      estimatedRequiredBytes: DownloadStorageEstimates.maxSurahBytes,
    );
    if (isStorageLow) {
      emit(const DownloadButtonState.pending(lowStorageWarning: true));
    }

    try {
      final Either<Failure, void> result = await _downloadSurah(
        surahId: _url,
        surahTitle: surahTitle,
        reciterName: _reciterName,
        reciterId: _reciterId,
      );

      await result.fold(
        (failure) async {
          if (failure is NetworkFailure) {
            emit(
              DownloadButtonState.networkError(errorMessage: failure.message),
            );
          } else {
            emit(DownloadButtonState.failed(errorMessage: failure.message));
          }
        },
        (_) async {
          // Success means download started (enqueued).
          // Stream will handle updates.
        },
      );
    } catch (e, stackTrace) {
      logger.e(
        '[DownloadButtonBloc] Uncaught exception starting '
        'download: $e',
        error: e,
        stackTrace: stackTrace,
      );
      emit(DownloadButtonState.failed(errorMessage: 'Unexpected error: $e'));
    }
  }

  Future<void> _onCancel(Emitter<DownloadButtonState> emit) async {
    final Either<Failure, void> result = await _cancelDownload(_url);
    result.fold(
      (failure) =>
          emit(DownloadButtonState.failed(errorMessage: failure.message)),
      (_) {
        emit(const DownloadButtonState.cancelled());
      },
    );
  }

  Future<void> _onRequestPause(Emitter<DownloadButtonState> emit) async {
    final Either<Failure, void> result = await _pauseDownload(_url);
    result.fold(
      (failure) =>
          emit(DownloadButtonState.failed(errorMessage: failure.message)),
      (_) {
        // State will be updated by progress stream
      },
    );
  }

  Future<void> _onRequestResume(Emitter<DownloadButtonState> emit) async {
    final Either<Failure, void> result = await _resumeDownload(_url);
    result.fold(
      (failure) =>
          emit(DownloadButtonState.failed(errorMessage: failure.message)),
      (_) {
        // State will be updated by progress stream
      },
    );
  }

  void _onProgressUpdated(
    double progress,
    int downloadedBytes,
    int totalBytes,
    Emitter<DownloadButtonState> emit,
  ) {
    // Discard stale progress events that arrive after the user cancelled or
    // the download already failed — the stream fires one last event before
    // the backend status transitions, which would briefly bounce the UI back
    // to "downloading" and invalidate accessibility-layer state assertions.
    final bool isTerminal = state.maybeWhen(
      cancelled: () => true,
      failed: (_) => true,
      orElse: () => false,
    );
    if (isTerminal) return;

    emit(
      DownloadButtonState.downloading(
        progress: progress,
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
      ),
    );
  }

  void _onCompleted(Emitter<DownloadButtonState> emit) {
    // We intentionally don't cancel the subscription here.
    // Keeps the widget reactive in case the file gets deleted
    // globally or redownloaded
    emit(const DownloadButtonState.completed());
  }

  void _onFailed(String? errorMessage, Emitter<DownloadButtonState> emit) {
    // Keep listening in case of auto-retry or external recovery
    emit(DownloadButtonState.failed(errorMessage: errorMessage));
  }

  void _onCancelled(Emitter<DownloadButtonState> emit) {
    // Keep listening in case user restarts it as part of a batch
    emit(const DownloadButtonState.cancelled());
  }

  void _onPaused(Emitter<DownloadButtonState> emit) {
    // Keep listening to detect resume events
    emit(const DownloadButtonState.paused());
  }

  void _listenToProgress() {
    _progressSubscription?.cancel();
    _lastProgressUpdateTime = null;
    _progressSubscription = _observeDownloadProgress(_url).listen(
      (item) {
        // Prevent adding events if bloc is already closed
        if (isClosed) {
          return;
        }

        switch (item.status) {
          case DownloadStatus.pending:
            // Emit pending state when stream indicates download
            // is queued. This handles widget rebuild scenarios
            // (e.g., scroll off-screen)
            add(const DownloadButtonEvent.pendingDetected());
          case DownloadStatus.downloading:
            final DateTime now = clock.now();
            final bool shouldUpdate =
                _lastProgressUpdateTime == null ||
                now.difference(_lastProgressUpdateTime!).inMilliseconds > 150 ||
                item.progress >= 1.0;

            if (shouldUpdate) {
              _lastProgressUpdateTime = now;
              add(
                DownloadButtonEvent.progressUpdated(
                  progress: item.progress,
                  downloadedBytes: item.downloadedSize,
                  totalBytes: item.fileSize,
                ),
              );
            }
          case DownloadStatus.completed:
            add(const DownloadButtonEvent.completed());
          case DownloadStatus.failed:
            add(
              const DownloadButtonEvent.failed(errorMessage: 'Download failed'),
            );
          case DownloadStatus.cancelled:
            add(const DownloadButtonEvent.cancelled());
          case DownloadStatus.paused:
            add(const DownloadButtonEvent.paused());
        }
      },
      onError: (error) {
        // Prevent adding events if bloc is already closed
        if (isClosed) {
          return;
        }
        logger.e(
          '[DownloadButtonBloc][$_url] Progress stream '
          'error: $error',
        );
        add(DownloadButtonEvent.failed(errorMessage: 'Stream error: $error'));
      },
    );
  }

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    return super.close();
  }
}
