import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/athkar_category.dart';
import '../../domain/entities/athkar_item.dart';

part 'athkar_state.freezed.dart';

@freezed
sealed class AthkarState with _$AthkarState {
  const factory AthkarState.initial() = AthkarInitial;
  const factory AthkarState.loading() = AthkarLoading;
  const factory AthkarState.categoriesLoaded(List<AthkarCategory> categories) =
      AthkarCategoriesLoaded;
  const factory AthkarState.itemsLoaded({
    required List<AthkarItem> items,
    required Map<int, int> currentCounts,
  }) = AthkarItemsLoaded;
  const factory AthkarState.error(Failure failure) = AthkarError;
}

extension AthkarStateX on AthkarState {
  String? get errorMessage => switch (this) {
    AthkarError(:final failure) =>
      failure.message ?? 'An unexpected error occurred',
    _ => null,
  };
}
