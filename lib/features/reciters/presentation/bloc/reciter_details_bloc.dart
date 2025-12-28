import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/audio.dart';
import '../../../../core/entities/moshaf_entity.dart';
import '../../../../core/entities/reciter_entity.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/audio/audio_player_handler.dart';
import '../../../downloads/domain/entities/download_item.dart';
import '../../../downloads/domain/usecases/get_valid_completed_downloads_use_case.dart';
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
    this._getValidCompletedDownloadsUseCase,
  ) : super(const ReciterDetailsState()) {
    on<LoadSurahList>(_onLoadSurahList);
    on<SelectMoshaf>(_onSelectMoshaf);
    on<SelectSurah>(_onSelectSurah);
    on<RefreshSurahDownloadStatus>(_onRefreshSurahDownloadStatus);
    on<FilterSurahs>(_onFilterSurahs);
    on<PlaySurahRequested>(_onPlaySurahRequested);
  }

  void _onFilterSurahs(FilterSurahs event, Emitter<ReciterDetailsState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  final AudioPlayerHandler _audioHandler;
  final ConvertAudioEntitiesToSurahsUseCase _convertAudioEntitiesToSurahs;
  final RefreshSurahDownloadStatusUseCase _refreshSurahDownloadStatusUseCase;
  final GetValidCompletedDownloadsUseCase _getValidCompletedDownloadsUseCase;

  Future<void> _onLoadSurahList(
    LoadSurahList event,
    Emitter<ReciterDetailsState> emit,
  ) async {
    emit(state.copyWith(status: ReciterDetailsStatus.loading));
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
        // Note: Progress tracking is now handled by ReciterDownloadBloc
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

  Future<void> _onPlaySurahRequested(
    PlaySurahRequested event,
    Emitter<ReciterDetailsState> emit,
  ) async {
    final SurahEntity surah = event.surah;
    if (state.status != ReciterDetailsStatus.loaded) {
      return;
    }

    // Immediately update selected surah for UI feedback
    emit(state.copyWith(selectedSurahId: surah.id));

    try {
      // Find index
      final int surahIndex = state.surahList.indexWhere(
        (item) => item.id == surah.id,
      );

      if (surahIndex == -1) {
        return;
      }

      // Fetch valid downloads
      final Either<Failure, List<DownloadItem>> result =
          await _getValidCompletedDownloadsUseCase(surah.reciterName);

      final List<DownloadItem> reciterDownloads = result.getOrElse(() => []);

      // Create map
      final Map<String, String> downloadMap = {};
      for (final item in reciterDownloads) {
        downloadMap[item.url] = item.filePath;
      }

      // Build playlist with local files
      final List<AudioEntity> surahListWithDownloads = [];
      for (var i = 0; i < state.surahList.length; i++) {
        final SurahEntity currentSurah = state.surahList[i];
        final String? localPath = downloadMap[currentSurah.id];

        if (localPath != null) {
          surahListWithDownloads.add(
            _createLocalAudioEntity(currentSurah, localPath),
          );
        } else {
          surahListWithDownloads.add(currentSurah.audio);
        }
      }

      // Emit command to play
      emit(
        state.copyWith(
          playCommand: PlaySurahCommand(
            playlist: surahListWithDownloads,
            initialIndex: surahIndex,
          ),
        ),
      );

      // Clear command immediately after so it doesn't re-trigger
      emit(state.copyWith());
    } catch (e) {
      // Log error or ignoring
    }
  }

  AudioEntity _createLocalAudioEntity(SurahEntity surah, String localPath) {
    return surah.audio.copyWith(url: Uri.file(localPath).toString());
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
