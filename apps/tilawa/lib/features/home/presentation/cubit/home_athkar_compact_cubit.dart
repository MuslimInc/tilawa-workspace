import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/athkar/data/datasources/athkar_daily_progress_local_datasource.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_item.dart';
import 'package:tilawa/features/athkar/domain/pinned_athkar_display_order.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_by_category_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_categories_use_case.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import 'home_athkar_compact_state.dart';

/// Canonical daily athkar categories shown on Home.
const List<int> homeAthkarCompactCategoryIds = [1, 2, 3];

@injectable
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
    emit(state.copyWith(status: HomeAthkarRowStatus.loading));

    final DateTime effectiveNow = now ?? DateTime.now();
    final String dateKey = athkarDailyProgressDateKey(effectiveNow);

    final categoriesResult = await _getCategories(const NoParams());
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
        ),
      );
    }

    final ordered = _orderRows(rows, effectiveNow);
    emit(
      HomeAthkarCompactState(
        status: HomeAthkarRowStatus.ready,
        rows: ordered,
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

  List<HomeAthkarRowState> _orderRows(
    List<HomeAthkarRowState> rows,
    DateTime now,
  ) {
    if (rows.length <= 1) {
      return rows;
    }

    final AthkarTimeRelevance priority = now.hour < 17
        ? AthkarTimeRelevance.morning
        : AthkarTimeRelevance.evening;

    int rank(HomeAthkarRowState row) {
      final AthkarTimeRelevance relevance = athkarTimeRelevanceForIcon(
        row.category.icon,
      );
      if (relevance == priority) {
        return 0;
      }
      if (relevance == AthkarTimeRelevance.neutral) {
        return 1;
      }
      return 2;
    }

    final ordered = List<HomeAthkarRowState>.from(rows)
      ..sort((a, b) => rank(a).compareTo(rank(b)));
    return ordered;
  }
}
