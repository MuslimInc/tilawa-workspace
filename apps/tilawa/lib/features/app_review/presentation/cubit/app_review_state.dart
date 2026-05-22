import 'package:equatable/equatable.dart';
import 'package:tilawa_core/errors/failures.dart';

/// State for [AppReviewCubit].
class AppReviewState extends Equatable {
  const AppReviewState({
    this.isCheckingAvailability = false,
    this.isRequestingReview = false,
    this.isOpeningStore = false,
    this.isAvailable,
    this.failure,
  });

  final bool isCheckingAvailability;
  final bool isRequestingReview;
  final bool isOpeningStore;
  final bool? isAvailable;
  final Failure? failure;

  AppReviewState copyWith({
    bool? isCheckingAvailability,
    bool? isRequestingReview,
    bool? isOpeningStore,
    bool? isAvailable,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return AppReviewState(
      isCheckingAvailability:
          isCheckingAvailability ?? this.isCheckingAvailability,
      isRequestingReview: isRequestingReview ?? this.isRequestingReview,
      isOpeningStore: isOpeningStore ?? this.isOpeningStore,
      isAvailable: isAvailable ?? this.isAvailable,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  bool get isBusy =>
      isCheckingAvailability || isRequestingReview || isOpeningStore;

  @override
  List<Object?> get props => [
    isCheckingAvailability,
    isRequestingReview,
    isOpeningStore,
    isAvailable,
    failure,
  ];
}
