import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import '../../data/datasources/athkar_daily_progress_local_datasource.dart';
import '../../domain/entities/athkar_category.dart';
import '../../domain/entities/athkar_item.dart';
import '../../domain/usecases/get_athkar_by_category_use_case.dart';
import '../../domain/usecases/get_athkar_categories_use_case.dart';
import 'athkar_state.dart';

/// Cubit responsible for managing Athkar categories and items.
///
/// Strictly acts as a state machine, delegating logic to UseCases.
class AthkarCubit extends Cubit<AthkarState> {
  AthkarCubit(
    this._getCategories,
    this._getAthkarByCategory,
    this._dailyProgress,
  ) : super(const AthkarState.initial());

  final GetAthkarCategoriesUseCase _getCategories;
  final GetAthkarByCategoryUseCase _getAthkarByCategory;
  final AthkarDailyProgressLocalDataSource _dailyProgress;

  Future<void> _persistCounts(AthkarItemsLoaded state) async {
    if (state.items.isEmpty) {
      return;
    }
    final int categoryId = state.items.first.categoryId;
    await _dailyProgress.saveCounts(
      categoryId: categoryId,
      dateKey: athkarDailyProgressDateKey(DateTime.now()),
      remainingCounts: state.currentCounts,
    );
  }

  /// Loads all Athkar categories.
  Future<void> loadCategories() async {
    emit(const AthkarState.loading());
    final Either<Failure, List<AthkarCategory>> result = await _getCategories(
      const NoParams(),
    );
    result.fold(
      (failure) => emit(AthkarState.error(failure)),
      (categories) => emit(AthkarState.categoriesLoaded(categories)),
    );
  }

  /// Loads items for a specific category.
  ///
  /// When [restoreProgress] is true, restores today's saved remaining counts
  /// and resumes at the first incomplete dhikr. When false (default), starts a
  /// fresh pass with full counts and overwrites any mid-session snapshot.
  Future<void> loadAthkar(
    int categoryId, {
    bool restoreProgress = false,
  }) async {
    emit(const AthkarState.loading());
    final Either<Failure, List<AthkarItem>> result = await _getAthkarByCategory(
      categoryId,
    );
    await result.fold(
      (failure) async => emit(AthkarState.error(failure)),
      (items) async {
        final Map<int, int> fullCounts = {
          for (final AthkarItem item in items) item.id: item.count,
        };
        Map<int, int> counts = fullCounts;
        int resumeIndex = 0;

        if (restoreProgress) {
          final Map<int, int> saved = await _dailyProgress.loadCounts(
            categoryId: categoryId,
            dateKey: athkarDailyProgressDateKey(DateTime.now()),
          );
          if (saved.isNotEmpty) {
            counts = {
              for (final AthkarItem item in items)
                item.id: (saved[item.id] ?? item.count).clamp(0, item.count),
            };
            resumeIndex = resumeIndexForCounts(items, counts);
          }
        }

        final AthkarItemsLoaded next = AthkarItemsLoaded(
          items: items,
          currentCounts: counts,
          resumeIndex: resumeIndex,
        );
        emit(next);
        if (!restoreProgress) {
          // Fresh entry: overwrite snapshot so Home completion matches a new pass.
          unawaited(_persistCounts(next));
        }
      },
    );
  }

  /// First item with remaining repetitions, or `0` when all complete / empty.
  static int resumeIndexForCounts(
    List<AthkarItem> items,
    Map<int, int> currentCounts,
  ) {
    for (int i = 0; i < items.length; i++) {
      final int remaining = currentCounts[items[i].id] ?? 0;
      if (remaining > 0) {
        return i;
      }
    }
    return 0;
  }

  /// Decrements the counter for a specific Athkar item.
  void decrementCount(int athkarId) {
    if (state is AthkarItemsLoaded) {
      final s = state as AthkarItemsLoaded;
      final currentCount = s.currentCounts[athkarId] ?? 0;
      if (currentCount > 0) {
        final updatedCounts = Map<int, int>.from(s.currentCounts);
        updatedCounts[athkarId] = currentCount - 1;
        final next = s.copyWith(currentCounts: updatedCounts);
        emit(next);
        unawaited(_persistCounts(next));
      }
    }
  }

  /// Resets the counter for a specific Athkar item to its original value.
  void resetCount(int athkarId) {
    if (state is AthkarItemsLoaded) {
      final s = state as AthkarItemsLoaded;
      final item = s.items.firstWhere((i) => i.id == athkarId);
      final updatedCounts = Map<int, int>.from(s.currentCounts);
      updatedCounts[athkarId] = item.count;
      final next = s.copyWith(currentCounts: updatedCounts);
      emit(next);
      unawaited(_persistCounts(next));
    }
  }
}
