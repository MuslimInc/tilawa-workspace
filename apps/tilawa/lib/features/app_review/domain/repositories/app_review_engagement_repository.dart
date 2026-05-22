import '../entities/app_review_engagement.dart';
import '../entities/app_review_signal.dart';

/// Local persistence for review trigger counters and cooldown state.
abstract class AppReviewEngagementRepository {
  Future<AppReviewEngagement> load();

  Future<void> save(AppReviewEngagement engagement);

  /// Records one app session (at most once per calendar day).
  Future<AppReviewEngagement> recordSession({required String dayKey});

  Future<AppReviewEngagement> recordSignal(
    AppReviewSignal signal, {
    required String dayKey,
  });

  Future<AppReviewEngagement> recordPromptShown({required int shownAtMs});
}
