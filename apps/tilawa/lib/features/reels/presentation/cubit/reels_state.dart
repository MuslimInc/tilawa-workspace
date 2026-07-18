import 'package:equatable/equatable.dart';

import '../../domain/entities/reel.dart';
import '../../domain/entities/reel_category.dart';
import '../../domain/entities/reel_engagement.dart';

enum ReelsStatus { initial, loading, ready, empty, error }

final class ReelsState extends Equatable {
  const ReelsState({
    this.status = ReelsStatus.initial,
    this.reels = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.currentIndex = 0,
    this.engagement = const {},
    this.errorMessage,
    this.burstReactionReelId,
  });

  final ReelsStatus status;
  final List<Reel> reels;
  final List<ReelCategory> categories;
  final int? selectedCategoryId;
  final int currentIndex;
  final Map<int, ReelEngagement> engagement;
  final String? errorMessage;

  /// Triggers heart-burst animation when set to a reel id.
  final int? burstReactionReelId;

  Reel? get currentReel =>
      reels.isEmpty || currentIndex < 0 || currentIndex >= reels.length
      ? null
      : reels[currentIndex];

  ReelsState copyWith({
    ReelsStatus? status,
    List<Reel>? reels,
    List<ReelCategory>? categories,
    int? selectedCategoryId,
    bool clearCategory = false,
    int? currentIndex,
    Map<int, ReelEngagement>? engagement,
    String? errorMessage,
    bool clearError = false,
    int? burstReactionReelId,
    bool clearBurst = false,
  }) {
    return ReelsState(
      status: status ?? this.status,
      reels: reels ?? this.reels,
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      currentIndex: currentIndex ?? this.currentIndex,
      engagement: engagement ?? this.engagement,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      burstReactionReelId: clearBurst
          ? null
          : (burstReactionReelId ?? this.burstReactionReelId),
    );
  }

  @override
  List<Object?> get props => [
    status,
    reels,
    categories,
    selectedCategoryId,
    currentIndex,
    engagement,
    errorMessage,
    burstReactionReelId,
  ];
}
