import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../main.dart';
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
    required String reciterName,
    required int reciterId,
    required CheckSurahDownloadedUseCase checkSurahDownloaded,
    required DownloadSurahUseCase downloadSurah,
    required CancelDownloadUseCase cancelDownload,
    required ObserveDownloadProgressUseCase observeDownloadProgress,
    bool? initialIsDownloaded,
    bool? initialIsDownloading,
    double? initialProgress,
  }) : _url = url.trim(),
       _reciterName = reciterName,
       _reciterId = reciterId,
       _checkSurahDownloaded = checkSurahDownloaded,
       _downloadSurah = downloadSurah,
       _cancelDownload = cancelDownload,
       _observeDownloadProgress = observeDownloadProgress,
       _initialIsDownloaded = initialIsDownloaded,
       _initialIsDownloading = initialIsDownloading,
       _initialProgress = initialProgress,
       super(const DownloadButtonState.initial()) {
    on<DownloadButtonEvent>((event, emit) async {
      await event.map(
        initialize: (_) async => _onInitialize(emit),
        startDownload: (e) async => _onStartDownload(e.surahTitle, emit),
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
        pendingDetected: (_) async => emit(const DownloadButtonState.pending()),
      );
    });
  }

  final String _url;
  final String _reciterName;
  final int _reciterId;
  final CheckSurahDownloadedUseCase _checkSurahDownloaded;
  final DownloadSurahUseCase _downloadSurah;
  final CancelDownloadUseCase _cancelDownload;
  final ObserveDownloadProgressUseCase _observeDownloadProgress;

  final bool? _initialIsDownloaded;
  final bool? _initialIsDownloading;
  final double? _initialProgress;
  StreamSubscription<DownloadItem>? _progressSubscription;

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

    // 2. Otherwise, check if downloaded from repository (fallback)
    final Either<Failure, bool> isDownloadedResult =
        await _checkSurahDownloaded(surahId: _url, reciterName: _reciterName);

    final bool isDownloaded = isDownloadedResult.getOrElse(() => false);

    if (isDownloaded) {
      emit(const DownloadButtonState.completed());
    } else {
      // Start listening to progress to catch active downloads we might have missed
      _listenToProgress();
      emit(const DownloadButtonState.readyToDownload());
    }
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
      logger.d(
        '[DownloadButtonBloc] Ignoring startDownload event because state is $state',
      );
      return;
    }

    emit(const DownloadButtonState.pending());
    _listenToProgress();

    final Either<Failure, void> result = await _downloadSurah(
      surahId: _url,
      surahTitle: surahTitle,
      reciterName: _reciterName,
      reciterId: _reciterId,
    );

    await result.fold(
      (failure) async {
        if (failure is NetworkFailure) {
          emit(DownloadButtonState.networkError(errorMessage: failure.message));
        } else {
          emit(DownloadButtonState.failed(errorMessage: failure.message));
        }
      },
      (_) async {
        // Success means download started (enqueued).
        // Stream will handle updates.
        logger.d('[DownloadButtonBloc] Download started via UseCase');
      },
    );
  }

  Future<void> _onCancel(Emitter<DownloadButtonState> emit) async {
    final Either<Failure, void> result = await _cancelDownload(_url);
    result.fold(
      (failure) => emit(
        const DownloadButtonState.failed(errorMessage: 'Failed to cancel'),
      ),
      (_) {
        emit(const DownloadButtonState.cancelled());
        _progressSubscription?.cancel();
      },
    );
  }

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

  void _onCompleted(Emitter<DownloadButtonState> emit) {
    _progressSubscription?.cancel();
    emit(const DownloadButtonState.completed());
  }

  void _onFailed(String? errorMessage, Emitter<DownloadButtonState> emit) {
    // Keep listening in case of auto-retry or external recovery
    emit(DownloadButtonState.failed(errorMessage: errorMessage));
  }

  void _onCancelled(Emitter<DownloadButtonState> emit) {
    _progressSubscription?.cancel();
    emit(const DownloadButtonState.cancelled());
  }

  void _onPaused(Emitter<DownloadButtonState> emit) {
    // Keep listening to detect resume events
    emit(const DownloadButtonState.paused());
  }

  void _listenToProgress() {
    _progressSubscription?.cancel();
    _progressSubscription = _observeDownloadProgress(_url).listen(
      (item) {
        // Filter by reciter name?
        // The ID passed to observeDownloadProgress is the URL.
        // The returned item SHOULD match.
        // if (item.reciterName != _reciterName) {
        //   return;
        // }

        switch (item.status) {
          case DownloadStatus.pending:
            // Emit pending state when stream indicates download is queued
            // This handles widget rebuild scenarios (e.g., scroll off-screen)
            add(const DownloadButtonEvent.pendingDetected());
          case DownloadStatus.downloading:
            add(
              DownloadButtonEvent.progressUpdated(
                progress: item.progress,
                downloadedBytes: item.downloadedSize,
                totalBytes: item.fileSize,
              ),
            );
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
        add(
          const DownloadButtonEvent.failed(
            errorMessage: 'Progress stream error',
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    return super.close();
  }
}
