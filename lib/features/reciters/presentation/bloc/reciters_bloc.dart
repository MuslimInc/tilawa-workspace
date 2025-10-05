import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/features/reciters/domain/usecases/get_reciters.dart';
import 'package:muzakri/features/reciters/domain/usecases/get_reciters_by_letter.dart';
import 'package:muzakri/features/reciters/domain/usecases/search_reciters.dart'
    as search_usecase;
import 'package:muzakri/features/reciters/presentation/bloc/reciters_event.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciters_state.dart';

class RecitersBloc extends Bloc<RecitersEvent, RecitersState> {
  RecitersBloc({
    required GetReciters getReciters,
    required search_usecase.SearchReciters searchReciters,
    required GetRecitersByLetter getRecitersByLetter,
  }) : _getReciters = getReciters,
       _searchReciters = searchReciters,
       _getRecitersByLetter = getRecitersByLetter,
       super(const RecitersInitial()) {
    on<LoadReciters>(_onLoadReciters);
    on<SearchReciters>(_onSearchReciters);
    on<FilterByLetter>(_onFilterByLetter);
    on<ClearSearch>(_onClearSearch);
    on<ClearLetterFilter>(_onClearLetterFilter);
  }

  final GetReciters _getReciters;
  final search_usecase.SearchReciters _searchReciters;
  final GetRecitersByLetter _getRecitersByLetter;

  Future<void> _onLoadReciters(
    LoadReciters event,
    Emitter<RecitersState> emit,
  ) async {
    emit(const RecitersLoading());

    final result = await _getReciters();

    result.fold(
      (failure) =>
          emit(RecitersError(failure.message ?? 'Failed to load reciters')),
      (reciters) =>
          emit(RecitersLoaded(reciters: reciters, filteredReciters: reciters)),
    );
  }

  Future<void> _onSearchReciters(
    SearchReciters event,
    Emitter<RecitersState> emit,
  ) async {
    if (state is! RecitersLoaded) return;

    final currentState = state as RecitersLoaded;

    if (event.query.isEmpty) {
      emit(
        currentState.copyWith(
          searchQuery: '',
          filteredReciters: currentState.reciters,
          selectedLetter: null,
        ),
      );
      return;
    }

    final result = await _searchReciters(event.query);

    result.fold(
      (failure) => emit(RecitersError(failure.message ?? 'Search failed')),
      (filteredReciters) => emit(
        currentState.copyWith(
          searchQuery: event.query,
          filteredReciters: filteredReciters,
          selectedLetter: null,
        ),
      ),
    );
  }

  Future<void> _onFilterByLetter(
    FilterByLetter event,
    Emitter<RecitersState> emit,
  ) async {
    if (state is! RecitersLoaded) return;

    final currentState = state as RecitersLoaded;

    final result = await _getRecitersByLetter(event.letter);

    result.fold(
      (failure) => emit(RecitersError(failure.message ?? 'Filter failed')),
      (filteredReciters) => emit(
        currentState.copyWith(
          searchQuery: '',
          filteredReciters: filteredReciters,
          selectedLetter: event.letter,
        ),
      ),
    );
  }

  void _onClearSearch(ClearSearch event, Emitter<RecitersState> emit) {
    if (state is! RecitersLoaded) return;

    final currentState = state as RecitersLoaded;

    emit(
      currentState.copyWith(
        searchQuery: '',
        filteredReciters: currentState.reciters,
        selectedLetter: null,
      ),
    );
  }

  void _onClearLetterFilter(
    ClearLetterFilter event,
    Emitter<RecitersState> emit,
  ) {
    if (state is! RecitersLoaded) return;

    final currentState = state as RecitersLoaded;

    emit(
      currentState.copyWith(
        searchQuery: '',
        filteredReciters: currentState.reciters,
        selectedLetter: null,
      ),
    );
  }
}
