import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import '../../domain/entities/history_entity.dart';
import '../../domain/usecases/usecases.dart';

part 'history_bloc.freezed.dart';

// Events
@freezed
class HistoryEvent with _$HistoryEvent {
  const factory HistoryEvent.loadAllHistory() = _LoadAllHistory;
  const factory HistoryEvent.loadRecentHistory({@Default(20) int limit}) =
      _LoadRecentHistory;
  const factory HistoryEvent.searchHistory(String query) = _SearchHistory;
  const factory HistoryEvent.clearSearch() = _ClearSearch;
  const factory HistoryEvent.deleteHistory(String id) = _DeleteHistory;
  const factory HistoryEvent.clearAllHistory() = _ClearAllHistory;
  const factory HistoryEvent.refreshHistory() = _RefreshHistory;
}

// States
@freezed
abstract class HistoryState with _$HistoryState {
  const factory HistoryState({
    @Default([]) List<HistoryEntity> historyList,
    @Default([]) List<HistoryEntity> filteredList,
    @Default(HistoryStatus.initial) HistoryStatus status,
    @Default('') String searchQuery,
    Failure? failure,
    @Default(0) int totalListeningTimeMs,
  }) = _HistoryState;
}

enum HistoryStatus { initial, loading, loaded, error, empty }

@injectable
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc(
    this._getAllHistoryUseCase,
    this._getRecentHistoryUseCase,
    this._deleteHistoryUseCase,
    this._clearAllHistoryUseCase,
    this._searchHistoryUseCase,
  ) : super(const HistoryState()) {
    on<_LoadAllHistory>(_onLoadAllHistory);
    on<_LoadRecentHistory>(_onLoadRecentHistory);
    on<_SearchHistory>(_onSearchHistory);
    on<_ClearSearch>(_onClearSearch);
    on<_DeleteHistory>(_onDeleteHistory);
    on<_ClearAllHistory>(_onClearAllHistory);
    on<_RefreshHistory>(_onRefreshHistory);
  }

  final GetAllHistoryUseCase _getAllHistoryUseCase;
  final GetRecentHistoryUseCase _getRecentHistoryUseCase;
  final DeleteHistoryUseCase _deleteHistoryUseCase;
  final ClearAllHistoryUseCase _clearAllHistoryUseCase;
  final SearchHistoryUseCase _searchHistoryUseCase;

  Future<void> _onLoadAllHistory(
    _LoadAllHistory event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(status: HistoryStatus.loading));

    final Either<Failure, List<HistoryEntity>> result =
        await _getAllHistoryUseCase.call();

    result.fold(
      (failure) =>
          emit(state.copyWith(status: HistoryStatus.error, failure: failure)),
      (history) {
        final int totalTime = history.fold(
          0,
          (total, h) => total + h.lastPositionMs,
        );
        emit(
          state.copyWith(
            status: history.isEmpty
                ? HistoryStatus.empty
                : HistoryStatus.loaded,
            historyList: history,
            filteredList: history,
            totalListeningTimeMs: totalTime,
          ),
        );
      },
    );
  }

  Future<void> _onLoadRecentHistory(
    _LoadRecentHistory event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(status: HistoryStatus.loading));

    final Either<Failure, List<HistoryEntity>> result =
        await _getRecentHistoryUseCase.call(limit: event.limit);

    result.fold(
      (failure) =>
          emit(state.copyWith(status: HistoryStatus.error, failure: failure)),
      (history) {
        final int totalTime = history.fold(
          0,
          (total, h) => total + h.lastPositionMs,
        );
        emit(
          state.copyWith(
            status: history.isEmpty
                ? HistoryStatus.empty
                : HistoryStatus.loaded,
            historyList: history,
            filteredList: history,
            totalListeningTimeMs: totalTime,
          ),
        );
      },
    );
  }

  Future<void> _onSearchHistory(
    _SearchHistory event,
    Emitter<HistoryState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(const HistoryEvent.clearSearch());
      return;
    }

    emit(
      state.copyWith(status: HistoryStatus.loading, searchQuery: event.query),
    );

    final Either<Failure, List<HistoryEntity>> result =
        await _searchHistoryUseCase.call(event.query);

    result.fold(
      (failure) =>
          emit(state.copyWith(status: HistoryStatus.error, failure: failure)),
      (history) {
        emit(
          state.copyWith(
            status: history.isEmpty
                ? HistoryStatus.empty
                : HistoryStatus.loaded,
            filteredList: history,
          ),
        );
      },
    );
  }

  void _onClearSearch(_ClearSearch event, Emitter<HistoryState> emit) {
    emit(
      state.copyWith(
        searchQuery: '',
        filteredList: state.historyList,
        status: state.historyList.isEmpty
            ? HistoryStatus.empty
            : HistoryStatus.loaded,
      ),
    );
  }

  Future<void> _onDeleteHistory(
    _DeleteHistory event,
    Emitter<HistoryState> emit,
  ) async {
    final Either<Failure, void> result = await _deleteHistoryUseCase.call(
      event.id,
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(status: HistoryStatus.error, failure: failure)),
      (_) {
        final List<HistoryEntity> updatedHistory = state.historyList
            .where((h) => h.id != event.id)
            .toList();
        final List<HistoryEntity> updatedFiltered = state.filteredList
            .where((h) => h.id != event.id)
            .toList();
        final int totalTime = updatedHistory.fold(
          0,
          (total, h) => total + h.lastPositionMs,
        );

        emit(
          state.copyWith(
            historyList: updatedHistory,
            filteredList: updatedFiltered,
            status: updatedHistory.isEmpty
                ? HistoryStatus.empty
                : HistoryStatus.loaded,
            totalListeningTimeMs: totalTime,
          ),
        );
      },
    );
  }

  Future<void> _onClearAllHistory(
    _ClearAllHistory event,
    Emitter<HistoryState> emit,
  ) async {
    final Either<Failure, void> result = await _clearAllHistoryUseCase.call();

    result.fold(
      (failure) =>
          emit(state.copyWith(status: HistoryStatus.error, failure: failure)),
      (_) {
        emit(const HistoryState(status: HistoryStatus.empty));
      },
    );
  }

  Future<void> _onRefreshHistory(
    _RefreshHistory event,
    Emitter<HistoryState> emit,
  ) async {
    add(const HistoryEvent.loadAllHistory());
  }
}
