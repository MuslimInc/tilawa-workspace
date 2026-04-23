import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import '../../domain/entities/athkar_category.dart';
import '../../domain/entities/athkar_item.dart';
import '../../domain/usecases/get_athkar_by_category_use_case.dart';
import '../../domain/usecases/get_athkar_categories_use_case.dart';
import 'athkar_state.dart';

/// Cubit responsible for managing Athkar categories and items.
///
/// Strictly acts as a state machine, delegating logic to UseCases.
@injectable
class AthkarCubit extends Cubit<AthkarState> {
  AthkarCubit(this._getCategories, this._getAthkarByCategory)
    : super(const AthkarState.initial());

  final GetAthkarCategoriesUseCase _getCategories;
  final GetAthkarByCategoryUseCase _getAthkarByCategory;

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
  Future<void> loadAthkar(int categoryId) async {
    emit(const AthkarState.loading());
    final Either<Failure, List<AthkarItem>> result = await _getAthkarByCategory(
      categoryId,
    );
    result.fold((failure) => emit(AthkarState.error(failure)), (items) {
      final counts = {for (final item in items) item.id: item.count};
      emit(AthkarState.itemsLoaded(items: items, currentCounts: counts));
    });
  }

  /// Decrements the counter for a specific Athkar item.
  void decrementCount(int athkarId) {
    if (state is AthkarItemsLoaded) {
      final s = state as AthkarItemsLoaded;
      final currentCount = s.currentCounts[athkarId] ?? 0;
      if (currentCount > 0) {
        final updatedCounts = Map<int, int>.from(s.currentCounts);
        updatedCounts[athkarId] = currentCount - 1;
        emit(s.copyWith(currentCounts: updatedCounts));
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
      emit(s.copyWith(currentCounts: updatedCounts));
    }
  }
}
