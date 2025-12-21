import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/moshaf_entity.dart';
import '../../../../core/entities/reciter_entity.dart';
import '../../../../shared/audio/audio_player_handler.dart';
import '../../../downloads/domain/usecases/download_all_surahs_use_case.dart';
import '../../../surah/domain/entities/surah_entity.dart';
import '../../../surah/domain/usecases/convert_media_items_to_surahs_use_case.dart';
import '../../../surah/domain/usecases/refresh_surah_download_status_use_case.dart';

part 'reciter_details_event.dart';
part 'reciter_details_state.dart';

@injectable
class ReciterDetailsBloc
    extends HydratedBloc<ReciterDetailsEvent, ReciterDetailsState> {
  ReciterDetailsBloc(
    this._audioHandler,
    this._convertMediaItemsToSurahs,

    this._refreshSurahDownloadStatusUseCase,
    this._downloadAllSurahsUseCase,
  ) : super(const ReciterDetailsState()) {
    on<LoadSurahList>(_onLoadSurahList);
    on<SelectMoshaf>(_onSelectMoshaf);
    on<SelectSurah>(_onSelectSurah);
    on<RefreshSurahDownloadStatus>(_onRefreshSurahDownloadStatus);
    on<DownloadAllSurahs>(_onDownloadAllSurahs);
  }
  final AudioPlayerHandler _audioHandler;
  final ConvertMediaItemsToSurahsUseCase _convertMediaItemsToSurahs;
  final RefreshSurahDownloadStatusUseCase _refreshSurahDownloadStatusUseCase;
  final DownloadAllSurahsUseCase _downloadAllSurahsUseCase;

  Future<void> _onLoadSurahList(
    LoadSurahList event,
    Emitter<ReciterDetailsState> emit,
  ) async {
    emit(state.copyWith(status: ReciterDetailsStatus.loading));
    try {
      final List<MediaItem>? mediaItemList = await _audioHandler
          .getSurahListForMoshaf(event.moshaf, reciterName: event.reciter.name);

      if (mediaItemList != null) {
        // Convert MediaItem list to Surah list with download status
        final List<SurahEntity> surahList = await _convertMediaItemsToSurahs(
          mediaItemList,
        );

        emit(
          state.copyWith(
            status: ReciterDetailsStatus.loaded,
            surahList: surahList,
            selectedMoshaf: event.moshaf,
          ),
        );
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
    await _downloadAllSurahsUseCase(
      surahs: event.surahs,
      reciterName: event.reciter.name,
      reciterId: event.reciter.id,
    );
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
