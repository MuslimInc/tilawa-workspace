import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:muzakri/audio_player_handler_impl.dart';
import 'package:muzakri/core/di/injection_container.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/domain/usecases/delete_download.dart';
import 'package:muzakri/features/downloads/domain/usecases/download_surah.dart';
import 'package:muzakri/features/downloads/domain/usecases/get_downloads_by_reciter.dart';

part 'downloads_bloc.freezed.dart';
part 'downloads_event.dart';
part 'downloads_state.dart';

class DownloadsBloc extends Bloc<DownloadsEvent, DownloadsState> {
  final GetDownloadsByReciter _getDownloadsByReciter;
  final DownloadSurah _downloadSurah;
  final DeleteDownload _deleteDownload;
  final DownloadsRepository _downloadsRepository;

  StreamSubscription<DownloadProgress>? _progressSubscription;

  DownloadsBloc({
    required GetDownloadsByReciter getDownloadsByReciter,
    required DownloadSurah downloadSurah,
    required DeleteDownload deleteDownload,
    required DownloadsRepository downloadsRepository,
  }) : _getDownloadsByReciter = getDownloadsByReciter,
       _downloadSurah = downloadSurah,
       _deleteDownload = deleteDownload,
       _downloadsRepository = downloadsRepository,
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

    // Listen to download progress
    _listenToProgress();
  }

  void _listenToProgress() {
    _progressSubscription = DownloadService.globalProgressStream.listen((
      progress,
    ) {
      // Update the download progress in the repository
      _downloadsRepository.updateDownloadProgress(
        progress.id,
        progress.status,
        progress.progress,
        progress.downloadedSize,
        progress.fileSize,
      );

      // Reload downloads to reflect the updated progress
      add(const LoadDownloads());
    });
  }

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadDownloads(
    LoadDownloads event,
    Emitter<DownloadsState> emit,
  ) async {
    emit(const DownloadsState.loading());

    final result = await _getDownloadsByReciter();
    result.fold(
      (failure) => emit(
        DownloadsState.error(failure.message ?? 'Failed to load downloads'),
      ),
      (downloads) => emit(DownloadsState.loaded(downloads)),
    );
  }

  Future<void> _onDownloadSurah(
    DownloadSurahEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    final result = await _downloadSurah(
      surahId: event.surahId,
      surahTitle: event.surahTitle,
      reciterName: event.reciterName,
      url: event.url,
    );

    result.fold(
      (failure) => emit(
        DownloadsState.error(failure.message ?? 'Failed to download surah'),
      ),
      (_) {
        // Reload downloads after successful download
        add(const LoadDownloads());
      },
    );
  }

  Future<void> _onDeleteDownload(
    DeleteDownloadEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    final result = await _deleteDownload(event.downloadId);
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
    // This would need to be implemented in the repository
    // For now, we'll just reload
    add(const LoadDownloads());
  }

  Future<void> _onClearAllDownloads(
    ClearAllDownloads event,
    Emitter<DownloadsState> emit,
  ) async {
    // This would need to be implemented in the repository
    // For now, we'll just reload
    add(const LoadDownloads());
  }

  Future<void> _onCheckSurahDownloaded(
    CheckSurahDownloadedEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    try {
      final isDownloaded = await _downloadsRepository.isSurahDownloaded(
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
      final download = await _downloadsRepository.getDownloadItem(
        event.downloadId,
      );
      if (download == null) {
        emit(DownloadsState.error('Download not found'));
        return;
      }

      final isValid = await _downloadsRepository.validateDownloadedFile(
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
      final validDownloads = await _downloadsRepository
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
      final download = await _downloadsRepository.getDownloadItem(
        event.downloadId,
      );
      if (download == null) {
        emit(DownloadsState.error('Download not found'));
        return;
      }

      // Validate file exists
      final fileExists = await _downloadsRepository.validateDownloadedFile(
        download,
      );
      if (!fileExists) {
        emit(DownloadsState.error('Downloaded file not found'));
        return;
      }

      // Create MediaItem and play
      final mediaItem = _downloadsRepository.createMediaItemFromDownload(
        download,
      );
      final audioHandler = sl<AudioPlayerHandlerImpl>();

      await audioHandler.updateQueue([mediaItem]);
      await audioHandler.pause();
      await audioHandler.skipToQueueItem(0);
      await audioHandler.play();

      emit(
        DownloadsState.playbackInitiated(message: 'Playing ${download.title}'),
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
      final validDownloads = await _downloadsRepository
          .getValidCompletedDownloads(event.reciterName);

      if (validDownloads.isEmpty) {
        emit(DownloadsState.error('No valid downloaded files found'));
        return;
      }

      // Create MediaItems and play
      final mediaItems = _downloadsRepository.createMediaItemsFromDownloads(
        validDownloads,
      );
      final audioHandler = sl<AudioPlayerHandlerImpl>();

      await audioHandler.updateQueue(mediaItems);
      await audioHandler.pause();
      await audioHandler.skipToQueueItem(0);
      await audioHandler.play();

      emit(
        DownloadsState.playbackInitiated(
          message:
              'Playing ${validDownloads.length} surahs from ${event.reciterName}',
        ),
      );
    } catch (e) {
      emit(DownloadsState.error('Error playing downloads: $e'));
    }
  }
}
