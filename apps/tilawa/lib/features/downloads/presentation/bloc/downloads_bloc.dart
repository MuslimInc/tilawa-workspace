// ignore_for_file: avoid_public_methods_on_bloc_instances
import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:stream_transform/stream_transform.dart';

import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import '../../../../main.dart';
import '../../data/models/download_progress.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/usecases/cancel_download_use_case.dart';
import '../../domain/usecases/check_download_access_use_case.dart';
import '../../domain/usecases/check_surah_downloaded_use_case.dart';
import '../../domain/usecases/clear_all_downloads_use_case.dart';
import '../../domain/usecases/delete_download_use_case.dart';
import '../../domain/usecases/delete_reciter_downloads_use_case.dart';
import '../../domain/usecases/download_surah_use_case.dart';
import '../../domain/usecases/get_download_item_use_case.dart';
import '../../domain/usecases/get_download_status_use_case.dart';
import '../../domain/usecases/get_downloads_by_reciter_use_case.dart';
import '../../domain/usecases/get_total_downloads_size_use_case.dart';
import '../../domain/usecases/get_valid_completed_downloads_use_case.dart';
import '../../domain/usecases/observe_global_download_progress_use_case.dart';
import '../../domain/usecases/play_all_downloads_use_case.dart';
import '../../domain/usecases/play_download_use_case.dart';
import '../../domain/usecases/remove_from_download_queue_use_case.dart';
import '../../domain/usecases/retry_download_use_case.dart';
import '../../domain/usecases/validate_downloaded_file_use_case.dart';
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
    required CheckSurahDownloadedUseCase checkSurahDownloaded,
    required ValidateDownloadedFileUseCase validateDownloadedFile,
    required GetValidCompletedDownloadsUseCase getValidCompletedDownloads,
    required CheckDownloadAccessUseCase checkDownloadAccess,
    required PlayDownloadUseCase playDownload,
    required PlayAllDownloadsUseCase playAllDownloads,
    required RetryDownloadUseCase retryDownload,
    required GetDownloadItemUseCase getDownloadItem,
    required CancelDownloadUseCase cancelDownload,
    required ObserveGlobalDownloadProgressUseCase observeGlobalDownloadProgress,
    required GetDownloadStatusUseCase getDownloadStatus,
    required RemoveFromDownloadQueueUseCase removeFromDownloadQueue,
  }) : _getDownloadsByReciter = getDownloadsByReciter,
       _downloadSurah = downloadSurah,
       _deleteDownload = deleteDownload,
       _deleteReciterDownloads = deleteReciterDownloads,
       _clearAllDownloads = clearAllDownloads,
       _getTotalDownloadsSize = getTotalDownloadsSize,
       _checkSurahDownloaded = checkSurahDownloaded,
       _validateDownloadedFile = validateDownloadedFile,
       _getValidCompletedDownloads = getValidCompletedDownloads,
       _checkDownloadAccess = checkDownloadAccess,
       _playDownload = playDownload,
       _playAllDownloads = playAllDownloads,
       _retryDownload = retryDownload,
       _getDownloadItem = getDownloadItem,
       _cancelDownload = cancelDownload,
       _observeGlobalDownloadProgress = observeGlobalDownloadProgress,
       _getDownloadStatus = getDownloadStatus,
       _removeFromDownloadQueue = removeFromDownloadQueue,
       super(const DownloadsState()) {
    on<LoadDownloads>(_onLoadDownloads, transformer: droppable());
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

    _listenToGlobalProgress();
  }
  final GetDownloadsByReciterUseCase _getDownloadsByReciter;
  final DownloadSurahUseCase _downloadSurah;
  final DeleteDownloadUseCase _deleteDownload;
  final DeleteReciterDownloadsUseCase _deleteReciterDownloads;
  final ClearAllDownloadsUseCase _clearAllDownloads;
  final GetTotalDownloadsSizeUseCase _getTotalDownloadsSize;
  final CheckSurahDownloadedUseCase _checkSurahDownloaded;
  final ValidateDownloadedFileUseCase _validateDownloadedFile;
  final GetValidCompletedDownloadsUseCase _getValidCompletedDownloads;
  final CheckDownloadAccessUseCase _checkDownloadAccess;
  final PlayDownloadUseCase _playDownload;
  final PlayAllDownloadsUseCase _playAllDownloads;
  final RetryDownloadUseCase _retryDownload;
  final GetDownloadItemUseCase _getDownloadItem;
  final CancelDownloadUseCase _cancelDownload;
  final ObserveGlobalDownloadProgressUseCase _observeGlobalDownloadProgress;
  final GetDownloadStatusUseCase _getDownloadStatus;
  final RemoveFromDownloadQueueUseCase _removeFromDownloadQueue;

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
      _progressSubscription = _observeGlobalDownloadProgress().listen(
        _handleGlobalProgressUpdate,
        onError: (e) => logger.e('[DownloadsBloc] Progress stream error: $e'),
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
    // Only show full loading spinner if we don't have data yet
    if (state.status != DownloadsStateStatus.loaded) {
      emit(state.copyWith(status: DownloadsStateStatus.loading));
    }
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

  /// Helper to check if a download can proceed (Premium check + Active check)
  Future<bool> _canStartDownload({
    required String downloadId,
    required String title,
    required String reciterName,
  }) async {
    // 1. Check premium access
    final Either<Failure, bool> accessResult = await _checkDownloadAccess(
      const NoParams(),
    );

    final bool canDownload = accessResult.getOrElse(() => false);
    if (!canDownload) {
      if (!_statusController.isClosed) {
        _statusController.add(
          const DownloadsStatus.premiumRequired(
            message:
                'Download feature requires premium subscription. Upgrade to unlock unlimited downloads!',
          ),
        );
      }
      return false;
    }

    // 2. Check if active
    try {
      final DownloadStatus? status = await _getDownloadStatus(downloadId);
      final bool isActive =
          status == DownloadStatus.downloading ||
          status == DownloadStatus.pending ||
          status == DownloadStatus.paused;

      if (isActive) {
        if (!_statusController.isClosed) {
          _statusController.add(
            DownloadsStatus.error(
              message:
                  'Surah "$title" by $reciterName is already being downloaded',
            ),
          );
        }
        return false;
      }
    } catch (e) {
      logger.w('[DownloadsBloc] Error checking if download is active: $e');
    }

    return true;
  }

  Future<void> _onDownloadSurah(
    DownloadSurahEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    // Check duplication (unique to new downloads)
    final Either<Failure, bool> downloadedResult = await _checkSurahDownloaded(
      surahId: event.surahId,
      reciterName: event.reciterName,
    );
    if (downloadedResult.getOrElse(() => false)) {
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

    // Use consolidated validation check
    // SurahId is URL, which is used as TaskId
    final bool canProceed = await _canStartDownload(
      downloadId: event.surahId,
      title: event.surahTitle,
      reciterName: event.reciterName,
    );
    if (!canProceed) {
      return;
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

    final Either<Failure, void> result = await _downloadSurah(
      surahId: event.surahId,
      surahTitle: event.surahTitle,
      reciterName: event.reciterName,
      reciterId: event.reciterId,
    );

    result.fold(
      (failure) {
        if (!_statusController.isClosed) {
          _statusController.add(
            DownloadsStatus.error(
              message: failure.message ?? 'Failed to download surah',
            ),
          );
        }
      },
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
    // Cancel the download if it's active in the queue
    try {
      final DownloadStatus? status = await _getDownloadStatus(event.downloadId);

      // Only cancel if it's actually running or pending
      // Cancelling a completed download might trigger a 'cancelled' event
      // which could revive the download in the db
      if (status == DownloadStatus.downloading ||
          status == DownloadStatus.pending ||
          status == DownloadStatus.paused) {
        final Either<Failure, void> cancelResult = await _cancelDownload(
          event.downloadId,
        );
        cancelResult.fold(
          (l) => logger.w(
            '[DownloadsBloc] Failed to cancel download: ${l.message}',
          ),
          (r) => null,
        );
      }
    } catch (e) {
      logger.w('[DownloadsBloc] Error cancelling download before deletion: $e');
    }

    // Also remove from the pending queue if present
    _removeFromDownloadQueue(event.downloadId);

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
    // Note: Active downloads cancellation is handled by the repository/usecase layer

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
        // Reload downloads after successful deletion
        add(const LoadDownloads());
      },
    );
  }

  Future<void> _onClearAllDownloads(
    ClearAllDownloads event,
    Emitter<DownloadsState> emit,
  ) async {
    // Note: Stopping active downloads is handled by the repository/usecase layer

    // Show loading state immediately to indicate ongoing operation
    emit(state.copyWith(status: DownloadsStateStatus.loading));

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
      final Either<Failure, bool> result = await _checkSurahDownloaded(
        surahId: event.surahId,
        reciterName: event.reciterName,
      );

      result.fold(
        (failure) {
          if (!_statusController.isClosed) {
            _statusController.add(
              DownloadsStatus.error(
                message: failure.message ?? 'Failed to check download status',
              ),
            );
          }
        },
        (isDownloaded) {
          if (!_statusController.isClosed) {
            _statusController.add(
              DownloadsStatus.surahDownloadStatus(
                surahId: event.surahId,
                reciterName: event.reciterName,
                isDownloaded: isDownloaded,
              ),
            );
          }
        },
      );
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
      final Either<Failure, DownloadItem?> result = await _getDownloadItem(
        event.downloadId,
      );
      final DownloadItem? download = result.getOrElse(() => null);

      if (download == null) {
        emit(
          state.copyWith(
            status: DownloadsStateStatus.error,
            errorMessage: 'Download not found',
          ),
        );
        return;
      }

      final Either<Failure, bool> validationResult =
          await _validateDownloadedFile(download);
      validationResult.fold(
        (failure) {
          if (!_statusController.isClosed) {
            _statusController.add(
              DownloadsStatus.error(
                message: failure.message ?? 'Failed to validate file',
              ),
            );
          }
        },
        (isValid) {
          if (!_statusController.isClosed) {
            _statusController.add(
              DownloadsStatus.fileValidationResult(
                downloadId: event.downloadId,
                isValid: isValid,
              ),
            );
          }
        },
      );
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
      final Either<Failure, List<DownloadItem>> result =
          await _getValidCompletedDownloads(event.reciterName);

      result.fold(
        (failure) {
          if (!_statusController.isClosed) {
            _statusController.add(
              DownloadsStatus.error(
                message:
                    failure.message ??
                    'Failed to get valid completed downloads',
              ),
            );
          }
        },
        (validDownloads) {
          if (!_statusController.isClosed) {
            _statusController.add(
              DownloadsStatus.validDownloadsLoaded(
                reciterName: event.reciterName,
                validDownloads: validDownloads,
              ),
            );
          }
        },
      );
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
      final Either<Failure, DownloadItem?> result = await _getDownloadItem(
        event.downloadId,
      );
      final DownloadItem? download = result.getOrElse(() => null);

      if (download == null) {
        if (!_statusController.isClosed) {
          _statusController.add(
            const DownloadsStatus.error(message: 'Download not found'),
          );
        }
        return;
      }

      // Validate file exists
      final Either<Failure, bool> validationResult =
          await _validateDownloadedFile(download);
      final bool fileExists = validationResult.getOrElse(() => false);

      if (!fileExists) {
        if (!_statusController.isClosed) {
          _statusController.add(
            const DownloadsStatus.error(message: 'Downloaded file not found'),
          );
        }
        return;
      }

      // Create MediaItem and play using UseCase
      final Either<Failure, void> playResult = await _playDownload(download);

      playResult.fold(
        (failure) {
          if (!_statusController.isClosed) {
            _statusController.add(
              DownloadsStatus.error(
                message: failure.message ?? 'Error playing surah',
              ),
            );
          }
        },
        (_) {
          if (!_statusController.isClosed) {
            _statusController.add(
              DownloadsStatus.playbackInitiated(
                message: 'Playing ${download.title}',
              ),
            );
          }
        },
      );
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
      final Either<Failure, List<DownloadItem>> result =
          await _getValidCompletedDownloads(event.reciterName);
      final List<DownloadItem> validDownloads = result.getOrElse(() => []);

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

      // Create MediaItems and play using UseCase
      final Either<Failure, void> playResult = await _playAllDownloads(
        PlayAllDownloadsParams(items: validDownloads),
      );

      playResult.fold(
        (failure) {
          if (!_statusController.isClosed) {
            _statusController.add(
              DownloadsStatus.error(
                message: failure.message ?? 'Error playing downloads',
              ),
            );
          }
        },
        (_) {
          if (!_statusController.isClosed) {
            _statusController.add(
              DownloadsStatus.playbackInitiated(
                message:
                    'Playing ${validDownloads.length} surahs from ${event.reciterName}',
              ),
            );
          }
        },
      );
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
      final Either<Failure, bool> result = await _checkDownloadAccess(
        const NoParams(),
      );
      result.fold(
        (failure) {
          if (!_statusController.isClosed) {
            _statusController.add(
              DownloadsStatus.error(
                message: failure.message ?? 'Failed to check premium access',
              ),
            );
          }
        },
        (canDownload) {
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
        },
      );
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
      final Either<Failure, DownloadItem?> result = await _getDownloadItem(
        event.downloadId,
      );
      final DownloadItem? downloadItem = result.getOrElse(() => null);
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

      // Use consolidated validation check
      final bool canProceed = await _canStartDownload(
        downloadId: event.downloadId,
        title: downloadItem.title,
        reciterName: downloadItem.reciterName,
      );
      if (!canProceed) {
        return;
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

      // Retry the download using UseCase
      final Either<Failure, void> retryResult = await _retryDownload(
        event.downloadId,
      );
      await retryResult.fold(
        (failure) async {
          if (!_statusController.isClosed) {
            _statusController.add(
              DownloadsStatus.error(
                message: failure.message ?? 'Failed to retry download',
              ),
            );
          }
        },
        (_) async {
          // Reload downloads after successful retry
          add(const LoadDownloads());
        },
      );
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
    await result.fold((failure) async {}, (downloads) async {
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
    });
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
