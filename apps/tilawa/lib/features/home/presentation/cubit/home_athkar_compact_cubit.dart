import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/features/athkar/data/datasources/athkar_daily_progress_local_datasource.dart';
import 'package:tilawa/features/athkar/domain/athkar_context_recommendation.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_item.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_by_category_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_categories_use_case.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import 'home_athkar_compact_state.dart';

/// Canonical daily athkar categories shown on Home.
const List<int> homeAthkarCompactCategoryIds = AthkarContextCategoryIds.daily;

class HomeAthkarCompactCubit extends Cubit<HomeAthkarCompactState> {
  HomeAthkarCompactCubit(
    this._getCategories,
    this._getAthkarByCategory,
    this._dailyProgress,
  ) : super(const HomeAthkarCompactState());

  final GetAthkarCategoriesUseCase _getCategories;
  final GetAthkarByCategoryUseCase _getAthkarByCategory;
  final AthkarDailyProgressLocalDataSource _dailyProgress;

  Future<void> load({DateTime? now}) async {
    if (isClosed) return;
    emit(state.copyWith(status: HomeAthkarRowStatus.loading));

    final DateTime effectiveNow = now ?? DateTime.now();
    final String dateKey = athkarDailyProgressDateKey(effectiveNow);

    final categoriesResult = await _getCategories(const NoParams());
    if (isClosed) return;
    final List<AthkarCategory> allCategories = categoriesResult.fold(
      (_) => const [],
      (value) => value,
    );
    final Map<int, AthkarCategory> byId = {
      for (final category in allCategories) category.id: category,
    };

    final List<HomeAthkarRowState> rows = [];
    for (final int categoryId in homeAthkarCompactCategoryIds) {
      final AthkarCategory? category = byId[categoryId];
      if (category == null) {
        continue;
      }

      final itemsResult = await _getAthkarByCategory(categoryId);
      final List<AthkarItem> items = itemsResult.fold(
        (_) => const [],
        (value) => value,
      );
      final Map<int, int> savedCounts = await _dailyProgress.loadCounts(
        categoryId: categoryId,
        dateKey: dateKey,
      );
      if (isClosed) return;

      final int totalRequired = items.fold<int>(
        0,
        (sum, item) => sum + item.count,
      );
      final int remaining = _remainingCount(items, savedCounts);

      final HomeAthkarCompletionState completion;
      if (savedCounts.isEmpty) {
        completion = HomeAthkarCompletionState.notStarted;
      } else if (remaining <= 0) {
        completion = HomeAthkarCompletionState.done;
      } else if (remaining < totalRequired) {
        completion = HomeAthkarCompletionState.inProgress;
      } else {
        completion = HomeAthkarCompletionState.notStarted;
      }

      rows.add(
        HomeAthkarRowState(
          category: category,
          completion: completion,
          remainingCount: remaining,
          totalRequired: totalRequired,
        ),
      );
    }

    emit(
      HomeAthkarCompactState(
        status: HomeAthkarRowStatus.ready,
        rows: rows,
      ),
    );
  }

  int _remainingCount(
    List<AthkarItem> items,
    Map<int, int> savedCounts,
  ) {
    if (savedCounts.isEmpty) {
      return items.fold<int>(0, (sum, item) => sum + item.count);
    }

    var remaining = 0;
    for (final AthkarItem item in items) {
      remaining += savedCounts[item.id] ?? item.count;
    }
    return remaining;
  }
}
