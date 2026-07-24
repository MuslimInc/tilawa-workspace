import 'package:equatable/equatable.dart';
import 'package:tilawa/features/athkar/domain/athkar_context_recommendation.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';

enum HomeAthkarRowStatus { initial, loading, ready }

enum HomeAthkarCompletionState { notStarted, inProgress, done }

/// Completion snapshot for one canonical daily athkar row.
final class HomeAthkarRowState extends Equatable {
  const HomeAthkarRowState({
    required this.category,
    this.completion = HomeAthkarCompletionState.notStarted,
    this.remainingCount = 0,
    this.totalRequired = 0,
  });

  final AthkarCategory category;
  final HomeAthkarCompletionState completion;
  final int remainingCount;

  /// Sum of per-item required counts for progress fraction.
  final int totalRequired;

  /// 0–1 completed fraction; null when no meaningful progress to show.
  double? get progressFraction {
    if (totalRequired <= 0) {
      return null;
    }
    if (completion == HomeAthkarCompletionState.notStarted) {
      return null;
    }
    final double value = (totalRequired - remainingCount) / totalRequired;
    return value.clamp(0.0, 1.0);
  }

  AthkarCategoryCompletion get domainCompletion => switch (completion) {
    HomeAthkarCompletionState.notStarted => AthkarCategoryCompletion.notStarted,
    HomeAthkarCompletionState.inProgress => AthkarCategoryCompletion.inProgress,
    HomeAthkarCompletionState.done => AthkarCategoryCompletion.done,
  };

  @override
  List<Object?> get props => [
    category,
    completion,
    remainingCount,
    totalRequired,
  ];
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

  Map<int, AthkarCategoryCompletion> get completionByCategoryId => {
    for (final HomeAthkarRowState row in rows)
      row.category.id: row.domainCompletion,
  };

  HomeAthkarRowState? rowForCategoryId(int? categoryId) {
    if (categoryId == null) {
      return null;
    }
    for (final HomeAthkarRowState row in rows) {
      if (row.category.id == categoryId) {
        return row;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [status, rows];
}

/// Completions map for the recommendation resolver when state is ready.
Map<int, AthkarCategoryCompletion> homeAthkarCompletions(
  HomeAthkarCompactState state,
) {
  if (state.status != HomeAthkarRowStatus.ready) {
    return {
      for (final int id in AthkarContextCategoryIds.daily)
        id: AthkarCategoryCompletion.notStarted,
    };
  }
  final Map<int, AthkarCategoryCompletion> map = {
    for (final int id in AthkarContextCategoryIds.daily)
      id: AthkarCategoryCompletion.notStarted,
  };
  map.addAll(state.completionByCategoryId);
  return map;
}

/// First incomplete daily athkar row, or the first row when all are done.
///
/// Prefer [resolveAthkarContextRecommendation] for Home tile context.
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
