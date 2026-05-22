import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_blocked_flow.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_engagement.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_prompt_moment.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_signal.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_trigger_policy.dart';
import 'package:tilawa/features/app_review/domain/repositories/app_review_engagement_repository.dart';
import 'package:tilawa/features/app_review/domain/repositories/app_review_repository.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_flow_guard.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_trigger_manager.dart';
import 'package:tilawa/features/app_review/domain/usecases/request_app_review_use_case.dart';

class _MemoryEngagementRepo implements AppReviewEngagementRepository {
  AppReviewEngagement state = AppReviewEngagement(
    sessionCount: 5,
    distinctActiveDays: 3,
    listeningCompletions: 2,
    firstSeenAtMs: DateTime.now()
        .subtract(const Duration(days: 10))
        .millisecondsSinceEpoch,
  );

  int sessionCalls = 0;
  int signalCalls = 0;

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
    state = state.copyWith(
      promptCount: state.promptCount + 1,
      lastPromptAtMs: shownAtMs,
    );
    return state;
  }
}

class _FailingRequestReview extends RequestAppReviewUseCase {
  _FailingRequestReview() : super(_FakeReviewRepo());

  @override
  Future<Either<Failure, void>> call() async =>
      const Left(AppReviewFailure.requestFailed());
}

class _FakeReviewRepo implements AppReviewRepository {
  int requestCount = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> openStoreListing() async {}

  @override
  Future<void> requestReview() async {
    requestCount++;
  }
}

void main() {
  late _MemoryEngagementRepo engagementRepo;
  late _FakeReviewRepo reviewRepo;
  late AppReviewFlowGuard flowGuard;
  late AppReviewTriggerManager manager;

  setUp(() {
    engagementRepo = _MemoryEngagementRepo();
    reviewRepo = _FakeReviewRepo();
    flowGuard = AppReviewFlowGuard();
    manager = AppReviewTriggerManager(
      engagementRepo,
      RequestAppReviewUseCase(reviewRepo),
      flowGuard,
      const AppReviewTriggerPolicy(
        minSessionCount: 3,
        minDistinctActiveDays: 2,
        minListeningCompletions: 1,
        promptDelay: Duration.zero,
        minimumAppAgeBeforePrompt: Duration(days: 1),
      ),
    );
  });

  test('does not prompt during sacred flow', () async {
    flowGuard.enter(AppReviewBlockedFlow.quranReading);
    final bool prompted = await manager.tryPromptIfEligible(
      AppReviewPromptMoment.listeningSessionCompleted,
    );
    expect(prompted, isFalse);
    expect(reviewRepo.requestCount, 0);
  });

  test('prompts when eligible on calm moment', () async {
    final bool prompted = await manager.tryPromptIfEligible(
      AppReviewPromptMoment.listeningSessionCompleted,
    );
    expect(prompted, isTrue);
    expect(reviewRepo.requestCount, 1);
    expect(engagementRepo.state.promptCount, 1);
  });

  test('respects lifetime prompt cap', () async {
    engagementRepo.state = engagementRepo.state.copyWith(promptCount: 2);
    final bool prompted = await manager.tryPromptIfEligible(
      AppReviewPromptMoment.listeningSessionCompleted,
    );
    expect(prompted, isFalse);
  });

  test('onSessionStarted records session', () async {
    await manager.onSessionStarted();
    expect(engagementRepo.sessionCalls, 1);
  });

  test('recordSignal delegates to repository', () async {
    await manager.recordSignal(AppReviewSignal.bookmarkCreated);
    expect(engagementRepo.signalCalls, 1);
    expect(engagementRepo.state.bookmarkCreates, 1);
  });

  test('sessionStarted moment never prompts', () async {
    final bool prompted = await manager.tryPromptIfEligible(
      AppReviewPromptMoment.sessionStarted,
    );
    expect(prompted, isFalse);
  });

  test('returns false when engagement is ineligible', () async {
    engagementRepo.state = const AppReviewEngagement();
    final bool prompted = await manager.tryPromptIfEligible(
      AppReviewPromptMoment.listeningSessionCompleted,
    );
    expect(prompted, isFalse);
  });

  test('returns false when review request fails', () async {
    final AppReviewTriggerManager failingManager = AppReviewTriggerManager(
      engagementRepo,
      _FailingRequestReview(),
      flowGuard,
      const AppReviewTriggerPolicy(
        minSessionCount: 3,
        minDistinctActiveDays: 2,
        minListeningCompletions: 1,
        promptDelay: Duration.zero,
        minimumAppAgeBeforePrompt: Duration(days: 1),
      ),
    );
    final bool prompted = await failingManager.tryPromptIfEligible(
      AppReviewPromptMoment.listeningSessionCompleted,
    );
    expect(prompted, isFalse);
    expect(engagementRepo.state.promptCount, 0);
  });

  test('respects cooldown between prompts', () async {
    engagementRepo.state = engagementRepo.state.copyWith(
      promptCount: 1,
      lastPromptAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    final bool prompted = await manager.tryPromptIfEligible(
      AppReviewPromptMoment.listeningSessionCompleted,
    );
    expect(prompted, isFalse);
  });

  test('prompts on returnedToRecitersTab when thresholds met', () async {
    final bool prompted = await manager.tryPromptIfEligible(
      AppReviewPromptMoment.returnedToRecitersTab,
    );
    expect(prompted, isTrue);
  });

  test('returns false for disallowed prompt moment', () async {
    final AppReviewTriggerManager strictManager = AppReviewTriggerManager(
      engagementRepo,
      RequestAppReviewUseCase(reviewRepo),
      flowGuard,
      const AppReviewTriggerPolicy(
        minSessionCount: 3,
        minDistinctActiveDays: 2,
        minListeningCompletions: 1,
        promptDelay: Duration.zero,
        minimumAppAgeBeforePrompt: Duration(days: 1),
        allowedPromptMoments: {AppReviewPromptMoment.bookmarkCreated},
      ),
    );
    final bool prompted = await strictManager.tryPromptIfEligible(
      AppReviewPromptMoment.listeningSessionCompleted,
    );
    expect(prompted, isFalse);
  });

  test('returns false when app is too new', () async {
    engagementRepo.state = engagementRepo.state.copyWith(
      firstSeenAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    final bool prompted = await manager.tryPromptIfEligible(
      AppReviewPromptMoment.listeningSessionCompleted,
    );
    expect(prompted, isFalse);
  });

  test('prompts on leftPrayerTimesTab when visits threshold met', () async {
    engagementRepo.state = engagementRepo.state.copyWith(
      prayerTimesTabVisits: 3,
    );
    final bool prompted = await manager.tryPromptIfEligible(
      AppReviewPromptMoment.leftPrayerTimesTab,
    );
    expect(prompted, isTrue);
  });

  test('aborts when sacred flow opens during prompt delay', () async {
    final AppReviewTriggerManager delayedManager = AppReviewTriggerManager(
      engagementRepo,
      RequestAppReviewUseCase(reviewRepo),
      flowGuard,
      const AppReviewTriggerPolicy(
        minSessionCount: 3,
        minDistinctActiveDays: 2,
        minListeningCompletions: 1,
        promptDelay: Duration(milliseconds: 40),
        minimumAppAgeBeforePrompt: Duration(days: 1),
      ),
    );
    final Future<bool> pending = delayedManager.tryPromptIfEligible(
      AppReviewPromptMoment.listeningSessionCompleted,
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    flowGuard.enter(AppReviewBlockedFlow.athkar);
    expect(await pending, isFalse);
    expect(reviewRepo.requestCount, 0);
  });

  test('blocks concurrent prompt attempts while one is pending', () async {
    final AppReviewTriggerManager delayedManager = AppReviewTriggerManager(
      engagementRepo,
      RequestAppReviewUseCase(reviewRepo),
      flowGuard,
      const AppReviewTriggerPolicy(
        minSessionCount: 3,
        minDistinctActiveDays: 2,
        minListeningCompletions: 1,
        promptDelay: Duration(milliseconds: 40),
        minimumAppAgeBeforePrompt: Duration(days: 1),
      ),
    );
    final Future<bool> first = delayedManager.tryPromptIfEligible(
      AppReviewPromptMoment.listeningSessionCompleted,
    );
    final bool second = await delayedManager.tryPromptIfEligible(
      AppReviewPromptMoment.listeningSessionCompleted,
    );
    expect(second, isFalse);
    expect(await first, isTrue);
  });
}
