import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/features/surah/domain/entities/surah_entity.dart';
import 'package:muzakri/features/surah/domain/usecases/convert_media_items_to_surahs_use_case.dart';
import 'package:muzakri/features/surah/domain/usecases/refresh_surah_download_status_use_case.dart';
import 'package:muzakri/shared/audio/audio_player_handler.dart';
import 'package:muzakri/shared/models/reciter_model.dart';

part 'reciter_details_event.dart';
part 'reciter_details_state.dart';

@injectable
class ReciterDetailsBloc
    extends HydratedBloc<ReciterDetailsEvent, ReciterDetailsState> {
  final AudioPlayerHandler _audioHandler;
  final ConvertMediaItemsToSurahsUseCase _convertMediaItemsToSurahs;
  final RefreshSurahDownloadStatusUseCase _refreshSurahDownloadStatusUseCase;

  ReciterDetailsBloc(
    this._audioHandler,
    this._convertMediaItemsToSurahs,
    this._refreshSurahDownloadStatusUseCase,
  ) : super(const ReciterDetailsInitial()) {
    on<LoadSurahList>(_onLoadSurahList);
    on<SelectMoshaf>(_onSelectMoshaf);
    on<SelectSurah>(_onSelectSurah);
    on<RefreshSurahDownloadStatus>(_onRefreshSurahDownloadStatus);
  }

  Future<void> _onLoadSurahList(
    LoadSurahList event,
    Emitter<ReciterDetailsState> emit,
  ) async {
    emit(const ReciterDetailsLoading());

    try {
      final mediaItemList = await _audioHandler.getSurahListForMoshaf(
        event.moshaf,
        reciterName: event.reciter.name,
      );

      if (mediaItemList != null) {
        // Convert MediaItem list to Surah list with download status
        final surahList = await _convertMediaItemsToSurahs(mediaItemList);

        emit(
          ReciterDetailsLoaded(
            surahList: surahList,
            selectedMoshaf: event.moshaf,
          ),
        );
      } else {
        emit(const ReciterDetailsError('Failed to load surah list'));
      }
    } catch (e) {
      emit(ReciterDetailsError('Error loading surah list: $e'));
    }
  }

  void _onSelectMoshaf(SelectMoshaf event, Emitter<ReciterDetailsState> emit) {
    if (state is! ReciterDetailsLoaded) return;

    final currentState = state as ReciterDetailsLoaded;
    emit(currentState.copyWith(selectedMoshaf: event.moshaf));
  }

  void _onSelectSurah(SelectSurah event, Emitter<ReciterDetailsState> emit) {
    if (state is! ReciterDetailsLoaded) return;

    final currentState = state as ReciterDetailsLoaded;
    emit(currentState.copyWith(selectedSurahId: event.surahId));
  }

  Future<void> _onRefreshSurahDownloadStatus(
    RefreshSurahDownloadStatus event,
    Emitter<ReciterDetailsState> emit,
  ) async {
    if (state is! ReciterDetailsLoaded) return;

    final currentState = state as ReciterDetailsLoaded;

    try {
      final updatedSurahList = await _refreshSurahDownloadStatusUseCase.call(
        currentSurahs: currentState.surahList,
        surahId: event.surahId,
        reciterName: event.reciterName,
      );

      emit(currentState.copyWith(surahList: updatedSurahList));
    } catch (e) {
      // Don't emit error for refresh, just keep current state
    }
  }

  @override
  ReciterDetailsState? fromJson(Map<String, dynamic> json) {
    // Reciter details should be loaded from repository, so we always start with initial state
    return const ReciterDetailsInitial();
  }

  @override
  Map<String, dynamic>? toJson(ReciterDetailsState state) {
    // Don't persist complex reciter details data - will reload from repository
    return null;
  }
}
