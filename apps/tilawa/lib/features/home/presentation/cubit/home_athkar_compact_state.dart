import 'package:equatable/equatable.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';

enum HomeAthkarRowStatus { initial, loading, ready }

enum HomeAthkarCompletionState { notStarted, inProgress, done }

/// Completion snapshot for one canonical daily athkar row.
final class HomeAthkarRowState extends Equatable {
  const HomeAthkarRowState({
    required this.category,
    this.completion = HomeAthkarCompletionState.notStarted,
    this.remainingCount = 0,
  });

  final AthkarCategory category;
  final HomeAthkarCompletionState completion;
  final int remainingCount;

  @override
  List<Object?> get props => [category, completion, remainingCount];
}

/// Three-row athkar compact card state for Home.
final class HomeAthkarCompactState extends Equatable {
  const HomeAthkarCompactState({
    this.status = HomeAthkarRowStatus.initial,
    this.rows = const [],
  });

  final HomeAthkarRowStatus status;
  final List<HomeAthkarRowState> rows;

  HomeAthkarCompactState copyWith({
    HomeAthkarRowStatus? status,
    List<HomeAthkarRowState>? rows,
  }) {
    return HomeAthkarCompactState(
      status: status ?? this.status,
      rows: rows ?? this.rows,
    );
  }

  @override
  List<Object?> get props => [status, rows];
}

/// First incomplete daily athkar row, or the first row when all are done.
HomeAthkarRowState? urgentHomeAthkarRow(HomeAthkarCompactState state) {
  if (state.status != HomeAthkarRowStatus.ready || state.rows.isEmpty) {
    return null;
  }
  for (final HomeAthkarRowState row in state.rows) {
    if (row.completion != HomeAthkarCompletionState.done) {
      return row;
    }
  }
  return state.rows.first;
}
