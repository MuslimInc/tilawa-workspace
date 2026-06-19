import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../../domain/entities/athkar_category.dart';
import '../../domain/entities/pinned_athkar_preference.dart';
import '../../domain/usecases/get_athkar_categories_use_case.dart';
import '../../domain/usecases/get_pinned_athkar_preference_use_case.dart';
import '../../domain/usecases/save_pinned_athkar_category_ids_use_case.dart';
import 'pinned_athkar_state.dart';

@injectable
class PinnedAthkarCubit extends Cubit<PinnedAthkarState> {
  PinnedAthkarCubit(
    this._getCategories,
    this._getPreference,
    this._saveCategoryIds,
  ) : super(const PinnedAthkarState());

  final GetAthkarCategoriesUseCase _getCategories;
  final GetPinnedAthkarPreferenceUseCase _getPreference;
  final SavePinnedAthkarCategoryIdsUseCase _saveCategoryIds;

  Future<void> load() async {
    emit(
      state.copyWith(status: PinnedAthkarStatus.loading, clearFailure: true),
    );

    final categoriesResult = await _getCategories(const NoParams());
    final preferenceResult = await _getPreference(const NoParams());

    final Failure? failure = categoriesResult.fold(
      (failure) => failure,
      (_) => preferenceResult.fold((failure) => failure, (_) => null),
    );
    if (failure != null) {
      emit(
        state.copyWith(status: PinnedAthkarStatus.failure, failure: failure),
      );
      return;
    }

    final List<AthkarCategory> categories = categoriesResult.getOrElse(
      () => const [],
    );
    final PinnedAthkarPreference preference = preferenceResult.getOrElse(
      () => const PinnedAthkarPreference(categoryIds: [], isCustomized: true),
    );
    final pinnedCategoryIds = _validCategoryIds(
      preference.categoryIds,
      categories,
    );

    emit(
      PinnedAthkarState(
        status: PinnedAthkarStatus.ready,
        categories: categories,
        pinnedCategoryIds: pinnedCategoryIds,
        isCustomized: preference.isCustomized,
      ),
    );
  }

  Future<void> toggleCategory(int categoryId) async {
    if (!state.hasLoaded) {
      return;
    }

    final nextIds = List<int>.of(state.pinnedCategoryIds);
    if (nextIds.contains(categoryId)) {
      nextIds.remove(categoryId);
    } else if (nextIds.length < PinnedAthkarState.maxPinnedCategories) {
      nextIds.add(categoryId);
    } else {
      return;
    }
    await _save(nextIds);
  }

  Future<void> movePinnedCategory({
    required int oldIndex,
    required int newIndex,
  }) async {
    if (!state.hasLoaded ||
        oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= state.pinnedCategoryIds.length ||
        newIndex >= state.pinnedCategoryIds.length ||
        oldIndex == newIndex) {
      return;
    }

    final nextIds = List<int>.of(state.pinnedCategoryIds);
    final id = nextIds.removeAt(oldIndex);
    nextIds.insert(newIndex, id);
    await _save(nextIds);
  }

  Future<void> _save(List<int> categoryIds) async {
    final nextIds = _validCategoryIds(categoryIds, state.categories);
    final previousState = state;
    emit(
      state.copyWith(
        status: PinnedAthkarStatus.saving,
        pinnedCategoryIds: nextIds,
        isCustomized: true,
        clearFailure: true,
      ),
    );

    final result = await _saveCategoryIds(nextIds);
    result.fold(
      (failure) => emit(
        previousState.copyWith(
          status: PinnedAthkarStatus.failure,
          failure: failure,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: PinnedAthkarStatus.ready,
          pinnedCategoryIds: nextIds,
          isCustomized: true,
          clearFailure: true,
        ),
      ),
    );
  }

  List<int> _validCategoryIds(
    List<int> categoryIds,
    List<AthkarCategory> categories,
  ) {
    final validIds = categories.map((category) => category.id).toSet();
    final seen = <int>{};
    return [
      for (final int id in categoryIds)
        if (validIds.contains(id) && seen.add(id)) id,
    ].take(PinnedAthkarState.maxPinnedCategories).toList(growable: false);
  }
}
