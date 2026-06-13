import 'package:injectable/injectable.dart';

import '../../domain/entities/app_review_engagement.dart';
import '../../domain/entities/app_review_signal.dart';
import '../../domain/repositories/app_review_engagement_repository.dart';
import '../datasources/app_review_engagement_local_datasource.dart';

@LazySingleton(as: AppReviewEngagementRepository)
class AppReviewEngagementRepositoryImpl
    implements AppReviewEngagementRepository {
  AppReviewEngagementRepositoryImpl(this._local);

  final AppReviewEngagementLocalDataSource _local;

  @override
  Future<AppReviewEngagement> load() => _local.read();

  @override
  Future<void> save(AppReviewEngagement engagement) => _local.write(engagement);

  @override
  Future<AppReviewEngagement> recordSession({required String dayKey}) async {
    final AppReviewEngagement current = await load();
    final int nowMs = DateTime.now().millisecondsSinceEpoch;

    if (current.lastSessionDayKey == dayKey) {
      return current;
    }

    final AppReviewEngagement updated = _touchActiveDay(
      current.copyWith(
        sessionCount: current.sessionCount + 1,
        lastSessionDayKey: dayKey,
        firstSeenAtMs: current.firstSeenAtMs ?? nowMs,
      ),
      dayKey,
    );
    await save(updated);
    return updated;
  }

  @override
  Future<AppReviewEngagement> recordSignal(
    AppReviewSignal signal, {
    required String dayKey,
  }) async {
    final AppReviewEngagement current = await load();
    final int nowMs = DateTime.now().millisecondsSinceEpoch;

    final AppReviewEngagement withSignal = switch (signal) {
      AppReviewSignal.listeningSessionCompleted => current.copyWith(
        listeningCompletions: current.listeningCompletions + 1,
      ),
      AppReviewSignal.prayerTimesTabVisited => current.copyWith(
        prayerTimesTabVisits: current.prayerTimesTabVisits + 1,
      ),
      AppReviewSignal.favoriteReciterAdded => current.copyWith(
        favoriteAdds: current.favoriteAdds + 1,
      ),
      AppReviewSignal.bookmarkCreated => current.copyWith(
        bookmarkCreates: current.bookmarkCreates + 1,
      ),
    };

    final AppReviewEngagement updated = _touchActiveDay(
      withSignal.copyWith(firstSeenAtMs: current.firstSeenAtMs ?? nowMs),
      dayKey,
    );
    await save(updated);
    return updated;
  }

  @override
  Future<AppReviewEngagement> recordPromptShown({
    required int shownAtMs,
  }) async {
    final AppReviewEngagement current = await load();
    final AppReviewEngagement updated = current.copyWith(
      promptCount: current.promptCount + 1,
      lastPromptAtMs: shownAtMs,
    );
    await save(updated);
    return updated;
  }

  AppReviewEngagement _touchActiveDay(
    AppReviewEngagement engagement,
    String dayKey,
  ) {
    if (engagement.lastActiveDayKey == dayKey) {
      return engagement;
    }
    return engagement.copyWith(
      distinctActiveDays: engagement.distinctActiveDays + 1,
      lastActiveDayKey: dayKey,
    );
  }
}
