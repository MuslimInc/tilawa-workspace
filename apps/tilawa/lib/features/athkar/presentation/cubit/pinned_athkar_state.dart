import 'package:equatable/equatable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/constants/pinned_athkar_constants.dart';
import '../../domain/entities/athkar_category.dart';

enum PinnedAthkarStatus { initial, loading, ready, saving, failure }

class PinnedAthkarState extends Equatable {
  const PinnedAthkarState({
    this.status = PinnedAthkarStatus.initial,
    this.categories = const [],
    this.pinnedCategoryIds = const [],
    this.isCustomized = false,
    this.failure,
  });

  final PinnedAthkarStatus status;
  final List<AthkarCategory> categories;
  final List<int> pinnedCategoryIds;
  final bool isCustomized;
  final Failure? failure;

  static const int maxPinnedCategories =
      PinnedAthkarConstants.maxPinnedCategories;

  List<AthkarCategory> get pinnedCategories {
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    return [
      for (final int id in pinnedCategoryIds)
        if (categoryById[id] != null) categoryById[id]!,
    ];
  }

  bool get canPinMore => pinnedCategoryIds.length < maxPinnedCategories;

  bool get hasLoaded => switch (status) {
    PinnedAthkarStatus.ready || PinnedAthkarStatus.saving => true,
    _ => false,
  };

  PinnedAthkarState copyWith({
    PinnedAthkarStatus? status,
    List<AthkarCategory>? categories,
    List<int>? pinnedCategoryIds,
    bool? isCustomized,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return PinnedAthkarState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      pinnedCategoryIds: pinnedCategoryIds ?? this.pinnedCategoryIds,
      isCustomized: isCustomized ?? this.isCustomized,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    categories,
    pinnedCategoryIds,
    isCustomized,
    failure,
  ];
}
