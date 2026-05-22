import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/presentation/cubit/app_review_state.dart';
import 'package:tilawa_core/errors/failures.dart';

void main() {
  test('isBusy is true when any operation is in flight', () {
    expect(const AppReviewState().isBusy, isFalse);
    expect(
      const AppReviewState(isCheckingAvailability: true).isBusy,
      isTrue,
    );
    expect(const AppReviewState(isRequestingReview: true).isBusy, isTrue);
    expect(const AppReviewState(isOpeningStore: true).isBusy, isTrue);
  });

  test('copyWith clears failure when requested', () {
    const AppReviewState original = AppReviewState(
      failure: AppReviewFailure.requestFailed(),
    );
    final AppReviewState cleared = original.copyWith(clearFailure: true);
    expect(cleared.failure, isNull);
  });
}
