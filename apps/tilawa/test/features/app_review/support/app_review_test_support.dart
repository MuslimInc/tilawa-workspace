import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_engagement.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_signal.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_trigger_policy.dart';
import 'package:tilawa/features/app_review/domain/repositories/app_review_engagement_repository.dart';
import 'package:tilawa/features/app_review/domain/repositories/app_review_repository.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_flow_guard.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_trigger_manager.dart';
import 'package:tilawa/features/app_review/domain/usecases/request_app_review_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

/// In-memory engagement store for app-review unit tests.
class MemoryEngagementRepository implements AppReviewEngagementRepository {
  MemoryEngagementRepository([AppReviewEngagement? initial])
    : state =
          initial ??
          AppReviewEngagement(
            sessionCount: 5,
            distinctActiveDays: 3,
            listeningCompletions: 2,
            firstSeenAtMs: DateTime.now()
                .subtract(const Duration(days: 10))
                .millisecondsSinceEpoch,
          );

  AppReviewEngagement state;

  int sessionCalls = 0;
  int signalCalls = 0;
  int promptShownCalls = 0;

  @override
  Future<AppReviewEngagement> load() async => state;

  @override
  Future<void> save(AppReviewEngagement engagement) async {
    state = engagement;
  }

  @override
  Future<AppReviewEngagement> recordSession({required String dayKey}) async {
    sessionCalls++;
    state = state.copyWith(sessionCount: state.sessionCount + 1);
    return state;
  }

  @override
  Future<AppReviewEngagement> recordSignal(
    AppReviewSignal signal, {
    required String dayKey,
  }) async {
    signalCalls++;
    state = switch (signal) {
      AppReviewSignal.listeningSessionCompleted => state.copyWith(
        listeningCompletions: state.listeningCompletions + 1,
      ),
      AppReviewSignal.prayerTimesTabVisited => state.copyWith(
        prayerTimesTabVisits: state.prayerTimesTabVisits + 1,
      ),
      AppReviewSignal.favoriteReciterAdded => state.copyWith(
        favoriteAdds: state.favoriteAdds + 1,
      ),
      AppReviewSignal.bookmarkCreated => state.copyWith(
        bookmarkCreates: state.bookmarkCreates + 1,
      ),
    };
    return state;
  }

  @override
  Future<AppReviewEngagement> recordPromptShown({
    required int shownAtMs,
  }) async {
    promptShownCalls++;
    state = state.copyWith(
      promptCount: state.promptCount + 1,
      lastPromptAtMs: shownAtMs,
    );
    return state;
  }
}

/// Tracks how many native review requests were made.
class FakeAppReviewRepository implements AppReviewRepository {
  int requestCount = 0;
  int storeOpenCount = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> openStoreListing() async {
    storeOpenCount++;
  }

  @override
  Future<void> requestReview() async {
    requestCount++;
  }
}

class FailingRequestAppReviewUseCase extends RequestAppReviewUseCase {
  FailingRequestAppReviewUseCase()
    : super(FakeAppReviewRepository());

  @override
  Future<Either<Failure, void>> call() async =>
      const Left(AppReviewFailure.requestFailed());
}

AppReviewEngagement productionEligibleEngagement() {
  return AppReviewEngagement(
    sessionCount: 2,
    distinctActiveDays: 1,
    listeningCompletions: 1,
    firstSeenAtMs: DateTime.now()
        .subtract(const Duration(days: 2))
        .millisecondsSinceEpoch,
  );
}

AppReviewTriggerManager createTriggerManager({
  required MemoryEngagementRepository engagementRepo,
  required FakeAppReviewRepository reviewRepo,
  required AppReviewFlowGuard flowGuard,
  AppReviewTriggerPolicy policy = const AppReviewTriggerPolicy(
    promptDelay: Duration.zero,
  ),
  RequestAppReviewUseCase? requestReview,
}) {
  return AppReviewTriggerManager(
    engagementRepo,
    requestReview ?? RequestAppReviewUseCase(reviewRepo),
    flowGuard,
    policy,
  );
}
