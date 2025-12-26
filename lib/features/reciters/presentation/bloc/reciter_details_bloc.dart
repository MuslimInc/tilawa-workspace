import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/audio.dart';
import '../../../../core/entities/moshaf_entity.dart';
import '../../../../core/entities/reciter_entity.dart';
import '../../../../shared/audio/audio_player_handler.dart';
import '../../../downloads/domain/entities/download_item.dart';
import '../../../downloads/domain/usecases/cancel_downloads_for_reciter_use_case.dart';
import '../../../downloads/domain/usecases/download_all_surahs_use_case.dart';
import '../../../downloads/domain/usecases/observe_reciter_downloads_use_case.dart';
import '../../../surah/domain/entities/surah_entity.dart';
import '../../../surah/domain/usecases/convert_audio_entities_to_surahs_use_case.dart';
import '../../../surah/domain/usecases/refresh_surah_download_status_use_case.dart';

part 'reciter_details_event.dart';
part 'reciter_details_state.dart';

@injectable
class ReciterDetailsBloc
    extends HydratedBloc<ReciterDetailsEvent, ReciterDetailsState> {
  ReciterDetailsBloc(
    this._audioHandler,
    this._convertAudioEntitiesToSurahs,
    this._refreshSurahDownloadStatusUseCase,
    this._downloadAllSurahsUseCase,
    this._cancelDownloadsForReciterUseCase,
    this._observeReciterDownloads,
  ) : super(const ReciterDetailsState()) {
    on<LoadSurahList>(_onLoadSurahList);
    on<SelectMoshaf>(_onSelectMoshaf);
    on<SelectSurah>(_onSelectSurah);
    on<RefreshSurahDownloadStatus>(_onRefreshSurahDownloadStatus);
    on<DownloadAllSurahs>(_onDownloadAllSurahs);
    on<FilterSurahs>(_onFilterSurahs);
    on<CancelDownloadAllSurahs>(_onCancelDownloadAllSurahs);
    on<UpdateDownloadProgress>(_onUpdateDownloadProgress);
  }

  void _onFilterSurahs(FilterSurahs event, Emitter<ReciterDetailsState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  final AudioPlayerHandler _audioHandler;
  final ConvertAudioEntitiesToSurahsUseCase _convertAudioEntitiesToSurahs;
  final RefreshSurahDownloadStatusUseCase _refreshSurahDownloadStatusUseCase;
  final DownloadAllSurahsUseCase _downloadAllSurahsUseCase;
  final CancelDownloadsForReciterUseCase _cancelDownloadsForReciterUseCase;
  final ObserveReciterDownloadsUseCase _observeReciterDownloads;

  StreamSubscription? _downloadsSubscription;
  String? _currentReciterName;
  final Map<String, bool> _completedSurahs = {}; // surahId -> isDownloaded
  final Set<String> _downloadingSurahs =
      {}; // surahId (that are actively downloading)

  Future<void> _onLoadSurahList(
    LoadSurahList event,
    Emitter<ReciterDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ReciterDetailsStatus.loading,
        downloadProgress: 0.0,
        isDownloadingAll: false,
        searchQuery: '',
      ),
    );
    _currentReciterName = event.reciter.name;
    _completedSurahs.clear();
    _downloadingSurahs.clear();
    _subscribeToDownloads();
    try {
      final List<AudioEntity>? audioEntities = await _audioHandler
          .getSurahListForMoshaf(event.moshaf, reciterName: event.reciter.name);

      if (audioEntities != null) {
        // Convert AudioEntity list to Surah list with download status
        final List<SurahEntity> surahList = await _convertAudioEntitiesToSurahs(
          audioEntities,
        );

        emit(
          state.copyWith(
            status: ReciterDetailsStatus.loaded,
            surahList: surahList,
            selectedMoshaf: event.moshaf,
          ),
        );

        // Initialize local status tracking from loaded list
        for (final surah in surahList) {
          if (surah.isDownloaded) {
            _completedSurahs[surah.id] = true;
          }
        }
        _updateProgressAndEmit();
      } else {
        emit(
          state.copyWith(
            status: ReciterDetailsStatus.error,
            errorMessage: 'Failed to load surah list',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ReciterDetailsStatus.error,
          errorMessage: 'Error loading surah list: $e',
        ),
      );
    }
  }

  void _onSelectMoshaf(SelectMoshaf event, Emitter<ReciterDetailsState> emit) {
    if (state.status != ReciterDetailsStatus.loaded) {
      return;
    }

    emit(state.copyWith(selectedMoshaf: event.moshaf));
  }

  void _onSelectSurah(SelectSurah event, Emitter<ReciterDetailsState> emit) {
    if (state.status != ReciterDetailsStatus.loaded) {
      return;
    }

    emit(state.copyWith(selectedSurahId: event.surahId));
  }

  Future<void> _onRefreshSurahDownloadStatus(
    RefreshSurahDownloadStatus event,
    Emitter<ReciterDetailsState> emit,
  ) async {
    if (state.status != ReciterDetailsStatus.loaded) {
      return;
    }

    try {
      final List<SurahEntity> updatedSurahList =
          await _refreshSurahDownloadStatusUseCase.call(
            currentSurahs: state.surahList,
            surahId: event.surahId,
            reciterName: event.reciterName,
          );

      emit(state.copyWith(surahList: updatedSurahList));
    } catch (e) {
      // Don't emit error for refresh, just keep current state
    }
  }

  Future<void> _onDownloadAllSurahs(
    DownloadAllSurahs event,
    Emitter<ReciterDetailsState> emit,
  ) async {
    // We don't optimistically update here to avoid massive rebuilds.
    // Instead, we rely on the repository's event stream (watched by DownloadButtonBloc)
    // to update individual button states efficiently.

    await _downloadAllSurahsUseCase(
      surahs: event.surahs,
      reciterName: event.reciter.name,
      reciterId: event.reciter.id,
    );
    // The start of download will be picked up by the stream listener
  }

  Future<void> _onCancelDownloadAllSurahs(
    CancelDownloadAllSurahs event,
    Emitter<ReciterDetailsState> emit,
  ) async {
    await _cancelDownloadsForReciterUseCase(event.reciterName);
    // Clearing local state will be handled by stream updates (cancelled/failed events)
    // But we can eagerly clear downloading set to update UI immediately
    _downloadingSurahs.clear();
    _updateProgressAndEmit();
  }

  void _subscribeToDownloads() {
    _downloadsSubscription?.cancel();
    if (_currentReciterName == null) {
      return;
    }

    _downloadsSubscription = _observeReciterDownloads(_currentReciterName!)
        .listen((item) {
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
            if (!_downloadingSurahs.contains(item.url)) {
              _downloadingSurahs.add(item.url);
              stateChanged = true;
            }
          } else if (item.status == DownloadStatus.failed ||
              item.status == DownloadStatus.cancelled) {
            if (_downloadingSurahs.contains(item.url)) {
              _downloadingSurahs.remove(item.url);
              stateChanged = true;
            }
          }

          if (stateChanged) {
            _updateProgressAndEmit();
          }
        });
  }

  void _updateProgressAndEmit() {
    if (state.surahList.isEmpty) {
      return;
    }

    final double progress = _completedSurahs.length / state.surahList.length;
    final bool isDownloadingAll = _downloadingSurahs.isNotEmpty;

    add(
      UpdateDownloadProgress(
        progress: progress,
        isDownloading: isDownloadingAll,
      ),
    );
  }

  void _onUpdateDownloadProgress(
    UpdateDownloadProgress event,
    Emitter<ReciterDetailsState> emit,
  ) {
    emit(
      state.copyWith(
        downloadProgress: event.progress,
        isDownloadingAll: event.isDownloading,
      ),
    );
  }

  @override
  Future<void> close() {
    _downloadsSubscription?.cancel();
    return super.close();
  }

  @override
  ReciterDetailsState? fromJson(Map<String, dynamic> json) {
    try {
      final statusString = json['status'] as String?;
      final ReciterDetailsStatus status = ReciterDetailsStatus.values
          .firstWhere(
            (e) => e.toString() == statusString,
            orElse: () => ReciterDetailsStatus.initial,
          );

      final surahListJson = json['surahList'] as List<dynamic>?;
      final List<SurahEntity> surahList =
          surahListJson
              ?.map((e) => SurahEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final moshafJson = json['selectedMoshaf'] as Map<String, dynamic>?;
      final MoshafEntity? selectedMoshaf = moshafJson != null
          ? MoshafEntity.fromJson(moshafJson)
          : null;

      final selectedSurahId = json['selectedSurahId'] as String?;

      // Only restore valid loaded state if we have data
      if (status == ReciterDetailsStatus.loaded && surahList.isNotEmpty) {
        return ReciterDetailsState(
          status: status,
          surahList: surahList,
          selectedMoshaf: selectedMoshaf,
          selectedSurahId: selectedSurahId,
        );
      }
      return const ReciterDetailsState();
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(ReciterDetailsState state) {
    if (state.status == ReciterDetailsStatus.loaded &&
        state.surahList.isNotEmpty) {
      return {
        'status': state.status.toString(),
        'surahList': state.surahList.map((e) => e.toJson()).toList(),
        'selectedMoshaf': state.selectedMoshaf?.toJson(),
        'selectedSurahId': state.selectedSurahId,
      };
    }
    return null;
  }
}
