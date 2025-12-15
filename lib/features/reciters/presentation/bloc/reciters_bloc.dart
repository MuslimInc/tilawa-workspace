import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/reciter.dart' as entity;
import '../../../../core/errors/failures.dart';
import '../../domain/usecases/get_reciters_use_case.dart';

part 'reciters_event.dart';
part 'reciters_state.dart';

@injectable
class RecitersBloc extends HydratedBloc<RecitersEvent, RecitersState> {
  RecitersBloc(this._getRecitersUseCase) : super(const RecitersInitial()) {
    on<LoadReciters>(_onLoadReciters);
    on<SearchRecitersEvent>(_onSearchReciters);
    on<FilterByLetter>(_onFilterByLetter);
    on<ClearLetterFilter>(_onClearLetterFilter);
    on<ClearSearch>(_onClearSearch);
    on<LanguageChanged>(_onLanguageChanged);
  }
  final GetRecitersUseCase _getRecitersUseCase;

  Future<void> _onLoadReciters(
    LoadReciters event,
    Emitter<RecitersState> emit,
  ) async {
    emit(const RecitersLoading());

    try {
      // Prefer domain use case to fetch once and share data
      final Either<Failure, List<entity.ReciterEntity>> result =
          await _getRecitersUseCase();
      final List<entity.ReciterEntity>? recitersData = result
          .fold<List<entity.ReciterEntity>?>(
            (_) => null,
            (entities) => entities,
          );

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
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;
    final List<entity.ReciterEntity> filteredReciters = _filterReciters(
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
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;
    final List<entity.ReciterEntity> filteredReciters = _filterReciters(
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
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;
    final List<entity.ReciterEntity> filteredReciters = _filterReciters(
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
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;
    final List<entity.ReciterEntity> filteredReciters = _filterReciters(
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

  List<entity.ReciterEntity> _filterReciters(
    List<entity.ReciterEntity> reciters,
    String searchQuery,
    String? selectedLetter,
  ) {
    var filtered = reciters;

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

  Future<void> _onLanguageChanged(
    LanguageChanged event,
    Emitter<RecitersState> emit,
  ) async {
    // If we have loaded reciters, refetch them with the new language
    if (state is RecitersLoaded) {
      await _onLoadReciters(const LoadReciters(), emit);
    }
  }

  @override
  RecitersState? fromJson(Map<String, dynamic> json) {
    // Reciters should be loaded from repository, so we always start with initial state
    return const RecitersInitial();
  }

  @override
  Map<String, dynamic>? toJson(RecitersState state) {
    // Don't persist complex reciters data - will reload from repository
    return null;
  }
}
