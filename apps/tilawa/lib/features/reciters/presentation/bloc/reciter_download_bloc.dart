import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import '../../../downloads/domain/entities/download_item.dart';
import '../../../downloads/domain/usecases/cancel_downloads_for_reciter_use_case.dart';
import '../../../downloads/domain/usecases/download_all_surahs_use_case.dart';
import '../../../downloads/domain/usecases/observe_reciter_downloads_use_case.dart';
import '../../../surah/domain/entities/surah_entity.dart';

part 'reciter_download_event.dart';
part 'reciter_download_state.dart';

@injectable
class ReciterDownloadBloc
    extends Bloc<ReciterDownloadEvent, ReciterDownloadState> {
  ReciterDownloadBloc(
    this._downloadAllSurahsUseCase,
    this._cancelDownloadsForReciterUseCase,
    this._observeReciterDownloads,
  ) : super(const ReciterDownloadState()) {
    on<StartReciterDownloadAll>(_onStartDownloadAll);
    on<CancelReciterDownloadAll>(_onCancelDownloadAll);
    on<UpdateReciterDownloadProgress>(_onUpdateProgress);
    on<InitializeReciterDownload>(_onInitialize);
  }

  final DownloadAllSurahsUseCase _downloadAllSurahsUseCase;
  final CancelDownloadsForReciterUseCase _cancelDownloadsForReciterUseCase;
  final ObserveReciterDownloadsUseCase _observeReciterDownloads;

  StreamSubscription? _downloadsSubscription;
  String? _currentReciterName;
  bool _isCancelling = false;
  bool _isBatchDownload = false;
  final Map<String, bool> _completedSurahs = {}; // surahId -> isDownloaded
  final Set<String> _downloadingSurahs = {}; // surahId (actively downloading)
  int _totalSurahsInRange = 0;

  void _onInitialize(
    InitializeReciterDownload event,
    Emitter<ReciterDownloadState> emit,
  ) {
    _currentReciterName = event.reciterName;
    _totalSurahsInRange = event.totalSurahs;
    _completedSurahs.clear();
    for (final String id in event.downloadedSurahIds) {
      _completedSurahs[id] = true;
    }
    _downloadingSurahs.clear();
    _isBatchDownload = false;

    _subscribeToDownloads();
    _updateProgressAndEmit(emit);
  }

  Future<void> _onStartDownloadAll(
    StartReciterDownloadAll event,
    Emitter<ReciterDownloadState> emit,
  ) async {
    _isBatchDownload = true;
    // Clear previous error message and set pending state
    emit(
      ReciterDownloadState(
        progress: state.progress,
        isDownloadingAll: true,
        isPending: true,
        downloadedCount: state.downloadedCount,
        totalCount: state.totalCount,
      ),
    );

    final Either<Failure, void> result = await _downloadAllSurahsUseCase(
      surahs: event.surahs,
      reciterName: event.reciter.name,
      reciterId: event.reciter.id,
    );

    result.fold(
      (failure) {
        // Handle immediate failures (like network error)
        _isBatchDownload = false;
        emit(
          state.copyWith(
            errorMessage: failure.message,
            isPending: false,
            isDownloadingAll: false,
          ),
        );
      },
      (_) {
        // Successfully enqueued - clear pending state
        // isDownloadingAll will be updated by the stream listener
        emit(state.copyWith(isPending: false));
      },
    );
  }

  Future<void> _onCancelDownloadAll(
    CancelReciterDownloadAll event,
    Emitter<ReciterDownloadState> emit,
  ) async {
    _isCancelling = true;
    _isBatchDownload = false;
    _downloadingSurahs.clear();
    _updateProgressAndEmit(emit);

    await _cancelDownloadsForReciterUseCase(event.reciterName);
    _isCancelling = false;
  }

  void _onUpdateProgress(
    UpdateReciterDownloadProgress event,
    Emitter<ReciterDownloadState> emit,
  ) {
    emit(
      state.copyWith(
        progress: event.progress,
        isDownloadingAll: event.isDownloading,
        isPending: false,
        downloadedCount: event.downloadedCount,
        totalCount: event.totalCount,
      ),
    );
  }

  void _subscribeToDownloads() {
    _downloadsSubscription?.cancel();
    if (_currentReciterName == null) {
      return;
    }

    _downloadsSubscription = _observeReciterDownloads(_currentReciterName!).listen((
      item,
    ) {
      var stateChanged = false;

      if (item.status == DownloadStatus.completed) {
        if (!_completedSurahs.containsKey(item.url)) {
          _completedSurahs[item.url] = true;
          stateChanged = true;
        }
        if (_downloadingSurahs.contains(item.url)) {
          _downloadingSurahs.remove(item.url);
          stateChanged = true;
        }
      } else if (item.status == DownloadStatus.downloading ||
          item.status == DownloadStatus.pending) {
        if (!_isCancelling && !_downloadingSurahs.contains(item.url)) {
          _downloadingSurahs.add(item.url);
          stateChanged = true;
        }
      } else if (item.status == DownloadStatus.failed) {
        if (_downloadingSurahs.contains(item.url)) {
          _downloadingSurahs.remove(item.url);
          stateChanged = true;
        }
      }

      if (_downloadingSurahs.isEmpty && _isBatchDownload) {
        _isBatchDownload = false;
        stateChanged = true;
      }

      if (stateChanged) {
        // Since this is a listener, we can't emit directly.
        // We'll add an event to the bloc.
        final double progress = _totalSurahsInRange > 0
            ? _completedSurahs.length / _totalSurahsInRange
            : 0.0;

        // isDownloadingAll should only be true when there are actual active downloads
        final bool hasActiveDownloads =
            _downloadingSurahs.isNotEmpty && _isBatchDownload;

        add(
          UpdateReciterDownloadProgress(
            progress: progress,
            isDownloading: hasActiveDownloads,
            downloadedCount: _completedSurahs.length,
            totalCount: _totalSurahsInRange,
          ),
        );
      }
    });
  }

  void _updateProgressAndEmit(Emitter<ReciterDownloadState> emit) {
    final double progress = _totalSurahsInRange > 0
        ? _completedSurahs.length / _totalSurahsInRange
        : 0.0;

    // isDownloadingAll should only be true when there are actual active downloads
    final bool hasActiveDownloads =
        _downloadingSurahs.isNotEmpty && _isBatchDownload;

    emit(
      state.copyWith(
        progress: progress,
        isDownloadingAll: hasActiveDownloads,
        isPending: false,
        downloadedCount: _completedSurahs.length,
        totalCount: _totalSurahsInRange,
      ),
    );
  }

  @override
  Future<void> close() {
    _downloadsSubscription?.cancel();
    return super.close();
  }
}
