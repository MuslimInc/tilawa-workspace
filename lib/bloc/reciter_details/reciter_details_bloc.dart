import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/audio_player_handler_impl.dart';
import 'package:muzakri/di_container.dart';
import 'package:muzakri/reciter_model.dart';

part 'reciter_details_event.dart';
part 'reciter_details_state.dart';

class ReciterDetailsBloc
    extends Bloc<ReciterDetailsEvent, ReciterDetailsState> {
  ReciterDetailsBloc() : super(const ReciterDetailsInitial()) {
    on<LoadSurahList>(_onLoadSurahList);
    on<SelectMoshaf>(_onSelectMoshaf);
    on<SelectSurah>(_onSelectSurah);
  }

  Future<void> _onLoadSurahList(
    LoadSurahList event,
    Emitter<ReciterDetailsState> emit,
  ) async {
    emit(const ReciterDetailsLoading());

    try {
      final audioHandler = getIt<AudioPlayerHandlerImpl>();
      final surahList = await audioHandler.getSurahListForMoshaf(event.moshaf);

      if (surahList != null) {
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
}
