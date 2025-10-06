import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/audio_player_handler_impl.dart';
import 'package:muzakri/core/di/injection_container.dart';
import 'package:muzakri/reciter_model.dart';

part 'reciters_event.dart';
part 'reciters_state.dart';

class RecitersBloc extends Bloc<RecitersEvent, RecitersState> {
  RecitersBloc() : super(const RecitersInitial()) {
    on<LoadReciters>(_onLoadReciters);
    on<SearchRecitersEvent>(_onSearchReciters);
    on<FilterByLetter>(_onFilterByLetter);
    on<ClearLetterFilter>(_onClearLetterFilter);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onLoadReciters(
    LoadReciters event,
    Emitter<RecitersState> emit,
  ) async {
    emit(const RecitersLoading());

    try {
      final audioHandler = sl<AudioPlayerHandlerImpl>();
      final recitersData = await audioHandler.getRecitersData();

      if (recitersData != null) {
        emit(
          RecitersLoaded(
            reciters: recitersData,
            filteredReciters: recitersData,
          ),
        );
      } else {
        emit(const RecitersError('Failed to load reciters'));
      }
    } catch (e) {
      emit(RecitersError('Error loading reciters: $e'));
    }
  }

  void _onSearchReciters(
    SearchRecitersEvent event,
    Emitter<RecitersState> emit,
  ) {
    if (state is! RecitersLoaded) return;

    final currentState = state as RecitersLoaded;
    final filteredReciters = _filterReciters(
      currentState.reciters,
      event.query,
      null, // Clear letter filter when searching
    );

    emit(
      currentState.copyWith(
        searchQuery: event.query,
        clearSelectedLetter: true,
        filteredReciters: filteredReciters,
      ),
    );
  }

  void _onFilterByLetter(FilterByLetter event, Emitter<RecitersState> emit) {
    if (state is! RecitersLoaded) return;

    final currentState = state as RecitersLoaded;
    final filteredReciters = _filterReciters(
      currentState.reciters,
      '', // Clear search when filtering by letter
      event.letter,
    );

    emit(
      currentState.copyWith(
        searchQuery: '',
        selectedLetter: event.letter,
        filteredReciters: filteredReciters,
      ),
    );
  }

  void _onClearLetterFilter(
    ClearLetterFilter event,
    Emitter<RecitersState> emit,
  ) {
    if (state is! RecitersLoaded) return;

    final currentState = state as RecitersLoaded;
    final filteredReciters = _filterReciters(
      currentState.reciters,
      currentState.searchQuery,
      null,
    );

    emit(
      currentState.copyWith(
        clearSelectedLetter: true,
        filteredReciters: filteredReciters,
      ),
    );
  }

  void _onClearSearch(ClearSearch event, Emitter<RecitersState> emit) {
    if (state is! RecitersLoaded) return;

    final currentState = state as RecitersLoaded;
    final filteredReciters = _filterReciters(
      currentState.reciters,
      '',
      currentState.selectedLetter,
    );

    emit(
      currentState.copyWith(
        searchQuery: '',
        filteredReciters: filteredReciters,
      ),
    );
  }

  List<Reciter> _filterReciters(
    List<Reciter> reciters,
    String searchQuery,
    String? selectedLetter,
  ) {
    List<Reciter> filtered = reciters;

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((reciter) {
        return reciter.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            reciter.letter.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by selected letter
    if (selectedLetter != null) {
      filtered = filtered.where((reciter) {
        return reciter.letter == selectedLetter;
      }).toList();
    }

    return filtered;
  }
}
