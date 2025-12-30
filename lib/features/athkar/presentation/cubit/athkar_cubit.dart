import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/analytics_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/athkar_category.dart';
import '../../domain/entities/athkar_item.dart';
import '../../domain/usecases/get_athkar_by_category_use_case.dart';
import '../../domain/usecases/get_athkar_categories_use_case.dart';
import 'athkar_state.dart';

@injectable
class AthkarCubit extends Cubit<AthkarState> {
  AthkarCubit(
    this._getCategories,
    this._getAthkarByCategory,
    this._analyticsService,
  ) : super(AthkarInitial());
  final GetAthkarCategoriesUseCase _getCategories;
  final GetAthkarByCategoryUseCase _getAthkarByCategory;
  final AnalyticsService _analyticsService;

  Future<void> loadCategories() async {
    emit(AthkarLoading());
    final Either<Failure, List<AthkarCategory>> result = await _getCategories(
      const NoParams(),
    );
    result.fold(
      (failure) =>
          emit(AthkarError(failure.message ?? 'Error loading categories')),
      (categories) {
        emit(AthkarCategoriesLoaded(categories));
      },
    );
  }

  Future<void> loadAthkar(int categoryId) async {
    emit(AthkarLoading());
    final Either<Failure, List<AthkarItem>> result = await _getAthkarByCategory(
      categoryId,
    );
    result.fold(
      (failure) => emit(AthkarError(failure.message ?? 'Error loading items')),
      (items) {
        final Map<int, int> counts = {
          for (final item in items) item.id: item.count,
        };
        emit(AthkarItemsLoaded(items: items, currentCounts: counts));
      },
    );
  }

  void decrementCount(int athkarId) {
    if (state is AthkarItemsLoaded) {
      final currentState = state as AthkarItemsLoaded;
      final currentCounts = Map<int, int>.from(currentState.currentCounts);
      if (currentCounts[athkarId]! > 0) {
        currentCounts[athkarId] = currentCounts[athkarId]! - 1;

        // Log decrement event
        final AthkarItem item = currentState.items.firstWhere(
          (element) => element.id == athkarId,
        );
        _analyticsService.logEvent(
          AnalyticsEvents.athkarItemDecrement,
          parameters: {
            AnalyticsParams.itemId: athkarId,
            AnalyticsParams.itemText: item.textAr.length > 100
                ? item.textAr.substring(0, 100)
                : item.textAr,
            AnalyticsParams.remainingCount: currentCounts[athkarId]!,
          },
        );

        if (currentCounts[athkarId] == 0) {
          _analyticsService.logEvent(
            AnalyticsEvents.athkarItemCompleted,
            parameters: {AnalyticsParams.itemId: athkarId},
          );
        }

        emit(
          AthkarItemsLoaded(
            items: currentState.items,
            currentCounts: currentCounts,
          ),
        );
      }
    }
  }

  void resetCount(int athkarId) {
    if (state is AthkarItemsLoaded) {
      final currentState = state as AthkarItemsLoaded;
      final currentCounts = Map<int, int>.from(currentState.currentCounts);
      final AthkarItem item = currentState.items.firstWhere(
        (element) => element.id == athkarId,
      );
      currentCounts[athkarId] = item.count;

      _analyticsService.logEvent(
        AnalyticsEvents.athkarItemReset,
        parameters: {AnalyticsParams.itemId: athkarId},
      );

      emit(
        AthkarItemsLoaded(
          items: currentState.items,
          currentCounts: currentCounts,
        ),
      );
    }
  }
}
