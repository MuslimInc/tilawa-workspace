import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

import '../../domain/usecases/search_reciters_use_case.dart';

part 'reciters_search_state.dart';

@injectable
class RecitersSearchCubit extends Cubit<RecitersSearchState> {
  RecitersSearchCubit(this._searchReciters)
    : super(const RecitersSearchInitial());

  static const Duration debounceDuration = Duration(milliseconds: 200);

  final SearchRecitersUseCase _searchReciters;
  Timer? _debounceTimer;
  int _searchGeneration = 0;

  void queryChanged(String rawQuery) {
    final String query = rawQuery.trim();
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      emit(const RecitersSearchInitial());
      return;
    }

    emit(RecitersSearchLoading(query: query));
    final int generation = ++_searchGeneration;
    _debounceTimer = Timer(debounceDuration, () {
      unawaited(_runSearch(query, generation));
    });
  }

  Future<void> _runSearch(String query, int generation) async {
    final result = await _searchReciters(query);
    if (generation != _searchGeneration || isClosed) {
      return;
    }

    result.fold(
      (failure) => emit(
        RecitersSearchError(query: query, message: failure.message ?? ''),
      ),
      (results) => emit(
        RecitersSearchLoaded(query: query, results: results),
      ),
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
