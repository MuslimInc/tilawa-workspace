import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_prompt_moment.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_trigger_policy.dart';

void main() {
  group('AppReviewTriggerPolicy', () {
    test('minFavoriteOrBookmarkActions mirrors minEngagementActions', () {
      const AppReviewTriggerPolicy policy = AppReviewTriggerPolicy(
        minEngagementActions: 4,
      );
      expect(policy.minFavoriteOrBookmarkActions, 4);
    });

    test('uses production defaults tuned for earlier calm prompts', () {
      const AppReviewTriggerPolicy policy = AppReviewTriggerPolicy();

      expect(policy.minSessionCount, 2);
      expect(policy.minDistinctActiveDays, 1);
      expect(policy.minListeningCompletions, 1);
      expect(policy.minPrayerTimesTabVisits, 2);
      expect(policy.minEngagementActions, 1);
      expect(policy.minimumAppAgeBeforePrompt, const Duration(days: 1));
      expect(policy.cooldownBetweenPrompts, const Duration(days: 90));
      expect(policy.maxLifetimePrompts, 2);
      expect(policy.promptDelay, const Duration(milliseconds: 1800));
    });

    test('allows all calm prompt moments by default', () {
      const AppReviewTriggerPolicy policy = AppReviewTriggerPolicy();

      expect(
        policy.allowedPromptMoments,
        containsAll(<AppReviewPromptMoment>{
          AppReviewPromptMoment.listeningSessionCompleted,
          AppReviewPromptMoment.leftPrayerTimesTab,
          AppReviewPromptMoment.returnedToRecitersTab,
          AppReviewPromptMoment.favoriteReciterAdded,
          AppReviewPromptMoment.bookmarkCreated,
        }),
      );
      expect(
        policy.allowedPromptMoments,
        isNot(contains(AppReviewPromptMoment.sessionStarted)),
      );
    });
  });
}
