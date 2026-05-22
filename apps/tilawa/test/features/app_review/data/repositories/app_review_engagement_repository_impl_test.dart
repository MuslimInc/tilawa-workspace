import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/data/datasources/app_review_engagement_local_datasource.dart';
import 'package:tilawa/features/app_review/data/repositories/app_review_engagement_repository_impl.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_engagement.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_signal.dart';

class _MemoryLocal implements AppReviewEngagementLocalDataSource {
  AppReviewEngagement data = const AppReviewEngagement();

  @override
  Future<AppReviewEngagement> read() async => data;

  @override
  Future<void> write(AppReviewEngagement engagement) async {
    data = engagement;
  }
}

void main() {
  late _MemoryLocal local;
  late AppReviewEngagementRepositoryImpl repository;

  setUp(() {
    local = _MemoryLocal();
    repository = AppReviewEngagementRepositoryImpl(local);
  });

  test('recordSession increments once per day', () async {
    final AppReviewEngagement first = await repository.recordSession(
      dayKey: '2026-05-22',
    );
    expect(first.sessionCount, 1);
    expect(first.distinctActiveDays, 1);
    expect(first.firstSeenAtMs, isNotNull);

    final AppReviewEngagement sameDay = await repository.recordSession(
      dayKey: '2026-05-22',
    );
    expect(sameDay.sessionCount, 1);

    final AppReviewEngagement nextDay = await repository.recordSession(
      dayKey: '2026-05-23',
    );
    expect(nextDay.sessionCount, 2);
    expect(nextDay.distinctActiveDays, 2);
  });

  test('recordSignal increments listening completions', () async {
    final AppReviewEngagement updated = await repository.recordSignal(
      AppReviewSignal.listeningSessionCompleted,
      dayKey: '2026-05-22',
    );
    expect(updated.listeningCompletions, 1);
    expect(updated.hasValueMoment, isTrue);
  });

  test('recordSignal increments prayer tab visits', () async {
    final AppReviewEngagement updated = await repository.recordSignal(
      AppReviewSignal.prayerTimesTabVisited,
      dayKey: '2026-05-22',
    );
    expect(updated.prayerTimesTabVisits, 1);
  });

  test('recordSignal increments favorite and bookmark counters', () async {
    final AppReviewEngagement favorite = await repository.recordSignal(
      AppReviewSignal.favoriteReciterAdded,
      dayKey: '2026-05-22',
    );
    final AppReviewEngagement bookmark = await repository.recordSignal(
      AppReviewSignal.bookmarkCreated,
      dayKey: '2026-05-22',
    );
    expect(favorite.favoriteAdds, 1);
    expect(bookmark.bookmarkCreates, 1);
  });

  test('recordPromptShown increments prompt metadata', () async {
    final AppReviewEngagement updated = await repository.recordPromptShown(
      shownAtMs: 42,
    );
    expect(updated.promptCount, 1);
    expect(updated.lastPromptAtMs, 42);
  });
}
