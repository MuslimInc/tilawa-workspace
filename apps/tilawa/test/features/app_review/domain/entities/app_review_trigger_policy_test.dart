import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_trigger_policy.dart';

void main() {
  test('minFavoriteOrBookmarkActions mirrors minEngagementActions', () {
    const AppReviewTriggerPolicy policy = AppReviewTriggerPolicy(
      minEngagementActions: 4,
    );
    expect(policy.minFavoriteOrBookmarkActions, 4);
  });
}
