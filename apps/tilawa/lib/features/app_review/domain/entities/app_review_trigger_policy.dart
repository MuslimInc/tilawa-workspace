import 'package:flutter/foundation.dart';

import 'app_review_prompt_moment.dart';

/// Tunable local rules for when Tilawa may request an in-app review.
///
/// Adjust thresholds here — no remote config required for MVP.
@immutable
class AppReviewTriggerPolicy {
  const AppReviewTriggerPolicy({
    this.minSessionCount = 4,
    this.minDistinctActiveDays = 2,
    this.minListeningCompletions = 1,
    this.minPrayerTimesTabVisits = 3,
    this.minEngagementActions = 1,
    this.cooldownBetweenPrompts = const Duration(days: 90),
    this.minimumAppAgeBeforePrompt = const Duration(days: 3),
    this.maxLifetimePrompts = 2,
    this.promptDelay = const Duration(milliseconds: 1800),
    this.allowedPromptMoments = const {
      AppReviewPromptMoment.listeningSessionCompleted,
      AppReviewPromptMoment.leftPrayerTimesTab,
      AppReviewPromptMoment.returnedToRecitersTab,
      AppReviewPromptMoment.favoriteReciterAdded,
      AppReviewPromptMoment.bookmarkCreated,
    },
  });

  /// App opens counted once per calendar day (not raw process restarts).
  final int minSessionCount;

  /// Distinct days with meaningful interaction.
  final int minDistinctActiveDays;

  final int minListeningCompletions;
  final int minPrayerTimesTabVisits;

  /// Favorites + bookmarks combined.
  final int minEngagementActions;

  /// Respects Play/App Store throttling in addition to OS-level limits.
  final Duration cooldownBetweenPrompts;

  /// No prompts during the first days after install.
  final Duration minimumAppAgeBeforePrompt;

  /// Hard cap — gratitude, not nagging.
  final int maxLifetimePrompts;

  /// Brief pause so the moment feels natural, not abrupt.
  final Duration promptDelay;

  final Set<AppReviewPromptMoment> allowedPromptMoments;

  int get minFavoriteOrBookmarkActions => minEngagementActions;
}
