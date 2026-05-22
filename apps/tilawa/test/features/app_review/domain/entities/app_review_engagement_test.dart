import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_engagement.dart';

void main() {
  test('engagementActions sums favorites and bookmarks', () {
    const AppReviewEngagement engagement = AppReviewEngagement(
      favoriteAdds: 2,
      bookmarkCreates: 3,
    );
    expect(engagement.engagementActions, 5);
  });

  test('hasValueMoment is true when any signal exists', () {
    expect(const AppReviewEngagement().hasValueMoment, isFalse);
    expect(
      const AppReviewEngagement(listeningCompletions: 1).hasValueMoment,
      isTrue,
    );
    expect(
      const AppReviewEngagement(prayerTimesTabVisits: 1).hasValueMoment,
      isTrue,
    );
    expect(
      const AppReviewEngagement(favoriteAdds: 1).hasValueMoment,
      isTrue,
    );
  });

  test('copyWith overrides provided fields', () {
    const AppReviewEngagement original = AppReviewEngagement(sessionCount: 1);
    final AppReviewEngagement updated = original.copyWith(
      sessionCount: 4,
      lastSessionDayKey: '2026-05-22',
    );
    expect(updated.sessionCount, 4);
    expect(updated.lastSessionDayKey, '2026-05-22');
  });

  test('props includes counters and timestamps', () {
    const AppReviewEngagement a = AppReviewEngagement(
      sessionCount: 2,
      firstSeenAtMs: 100,
    );
    const AppReviewEngagement b = AppReviewEngagement(
      sessionCount: 2,
      firstSeenAtMs: 100,
    );
    expect(a, equals(b));
  });
}
