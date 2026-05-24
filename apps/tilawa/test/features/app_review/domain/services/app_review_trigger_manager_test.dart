import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_blocked_flow.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_engagement.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_prompt_moment.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_signal.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_trigger_policy.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_flow_guard.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_trigger_manager.dart';

import '../../support/app_review_test_support.dart';

void main() {
  late MemoryEngagementRepository engagementRepo;
  late FakeAppReviewRepository reviewRepo;
  late AppReviewFlowGuard flowGuard;
  late AppReviewTriggerManager manager;

  setUp(() {
    engagementRepo = MemoryEngagementRepository();
    reviewRepo = FakeAppReviewRepository();
    flowGuard = AppReviewFlowGuard();
    manager = createTriggerManager(
      engagementRepo: engagementRepo,
      reviewRepo: reviewRepo,
      flowGuard: flowGuard,
      policy: const AppReviewTriggerPolicy(
        minSessionCount: 3,
        minDistinctActiveDays: 2,
        minListeningCompletions: 1,
        promptDelay: Duration.zero,
        minimumAppAgeBeforePrompt: const Duration(days: 1),
      ),
    );
  });

  group('session and signal recording', () {
    test('onSessionStarted records session', () async {
      await manager.onSessionStarted();
      expect(engagementRepo.sessionCalls, 1);
    });

    test('recordSignal delegates to repository', () async {
      await manager.recordSignal(AppReviewSignal.bookmarkCreated);
      expect(engagementRepo.signalCalls, 1);
      expect(engagementRepo.state.bookmarkCreates, 1);
    });
  });

  group('sacred flow blocking', () {
    test('does not prompt during sacred flow', () async {
      flowGuard.enter(AppReviewBlockedFlow.quranReading);
      final bool prompted = await manager.tryPromptIfEligible(
        AppReviewPromptMoment.listeningSessionCompleted,
      );
      expect(prompted, isFalse);
      expect(reviewRepo.requestCount, 0);
    });

    test('aborts when sacred flow opens during prompt delay', () async {
      final AppReviewTriggerManager delayedManager = createTriggerManager(
        engagementRepo: engagementRepo,
        reviewRepo: reviewRepo,
        flowGuard: flowGuard,
        policy: const AppReviewTriggerPolicy(
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
  });

  group('eligibility gates', () {
    test('sessionStarted moment never prompts', () async {
      final bool prompted = await manager.tryPromptIfEligible(
        AppReviewPromptMoment.sessionStarted,
      );
      expect(prompted, isFalse);
    });

    test('returns false when engagement is empty', () async {
      engagementRepo.state = const AppReviewEngagement();
      final bool prompted = await manager.tryPromptIfEligible(
        AppReviewPromptMoment.listeningSessionCompleted,
      );
      expect(prompted, isFalse);
    });

    test('returns false when session count is below threshold', () async {
      engagementRepo.state = engagementRepo.state.copyWith(sessionCount: 1);
      final bool prompted = await manager.tryPromptIfEligible(
        AppReviewPromptMoment.listeningSessionCompleted,
      );
      expect(prompted, isFalse);
    });

    test('returns false when distinct active days are below threshold', () async {
      engagementRepo.state = engagementRepo.state.copyWith(
        distinctActiveDays: 1,
      );
      final bool prompted = await manager.tryPromptIfEligible(
        AppReviewPromptMoment.listeningSessionCompleted,
      );
      expect(prompted, isFalse);
    });

    test('returns false when there is no value moment', () async {
      engagementRepo.state = engagementRepo.state.copyWith(
        listeningCompletions: 0,
        prayerTimesTabVisits: 0,
        favoriteAdds: 0,
        bookmarkCreates: 0,
      );
      final bool prompted = await manager.tryPromptIfEligible(
        AppReviewPromptMoment.listeningSessionCompleted,
      );
      expect(prompted, isFalse);
    });

    test('returns false when firstSeenAtMs is missing', () async {
      engagementRepo.state = const AppReviewEngagement(
        sessionCount: 5,
        distinctActiveDays: 3,
        listeningCompletions: 2,
      );
      final bool prompted = await manager.tryPromptIfEligible(
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

    test('returns false when no signal threshold is met', () async {
      engagementRepo.state = engagementRepo.state.copyWith(
        listeningCompletions: 0,
        prayerTimesTabVisits: 0,
        favoriteAdds: 0,
        bookmarkCreates: 0,
      );
      final bool prompted = await manager.tryPromptIfEligible(
        AppReviewPromptMoment.favoriteReciterAdded,
      );
      expect(prompted, isFalse);
    });

    test('returns false for disallowed prompt moment', () async {
      final AppReviewTriggerManager strictManager = createTriggerManager(
        engagementRepo: engagementRepo,
        reviewRepo: reviewRepo,
        flowGuard: flowGuard,
        policy: const AppReviewTriggerPolicy(
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
  });

  group('prompt caps and cooldown', () {
    test('prompts when eligible on calm moment', () async {
      final bool prompted = await manager.tryPromptIfEligible(
        AppReviewPromptMoment.listeningSessionCompleted,
      );
      expect(prompted, isTrue);
      expect(reviewRepo.requestCount, 1);
      expect(engagementRepo.state.promptCount, 1);
      expect(engagementRepo.promptShownCalls, 1);
    });

    test('respects lifetime prompt cap', () async {
      engagementRepo.state = engagementRepo.state.copyWith(promptCount: 2);
      final bool prompted = await manager.tryPromptIfEligible(
        AppReviewPromptMoment.listeningSessionCompleted,
      );
      expect(prompted, isFalse);
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

    test('prompts again after cooldown expires', () async {
      engagementRepo.state = engagementRepo.state.copyWith(
        promptCount: 1,
        lastPromptAtMs: DateTime.now()
            .subtract(const Duration(days: 91))
            .millisecondsSinceEpoch,
      );
      final bool prompted = await manager.tryPromptIfEligible(
        AppReviewPromptMoment.listeningSessionCompleted,
      );
      expect(prompted, isTrue);
      expect(engagementRepo.state.promptCount, 2);
    });

    test('returns false when review request fails', () async {
      final AppReviewTriggerManager failingManager = createTriggerManager(
        engagementRepo: engagementRepo,
        reviewRepo: reviewRepo,
        flowGuard: flowGuard,
        policy: const AppReviewTriggerPolicy(
          minSessionCount: 3,
          minDistinctActiveDays: 2,
          minListeningCompletions: 1,
          promptDelay: Duration.zero,
          minimumAppAgeBeforePrompt: Duration(days: 1),
        ),
        requestReview: FailingRequestAppReviewUseCase(),
      );
      final bool prompted = await failingManager.tryPromptIfEligible(
        AppReviewPromptMoment.listeningSessionCompleted,
      );
      expect(prompted, isFalse);
      expect(engagementRepo.state.promptCount, 0);
    });
  });

  group('prompt moments', () {
    test('prompts on returnedToRecitersTab when thresholds met', () async {
      final bool prompted = await manager.tryPromptIfEligible(
        AppReviewPromptMoment.returnedToRecitersTab,
      );
      expect(prompted, isTrue);
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

    test('does not prompt on leftPrayerTimesTab below visit threshold', () async {
      engagementRepo.state = engagementRepo.state.copyWith(
        listeningCompletions: 0,
        prayerTimesTabVisits: 1,
        favoriteAdds: 0,
        bookmarkCreates: 0,
      );
      final bool prompted = await manager.tryPromptIfEligible(
        AppReviewPromptMoment.leftPrayerTimesTab,
      );
      expect(prompted, isFalse);
    });

    test('prompts on favoriteReciterAdded when favorite exists', () async {
      engagementRepo.state = engagementRepo.state.copyWith(
        listeningCompletions: 0,
        prayerTimesTabVisits: 0,
        favoriteAdds: 1,
      );
      final bool prompted = await manager.tryPromptIfEligible(
        AppReviewPromptMoment.favoriteReciterAdded,
      );
      expect(prompted, isTrue);
    });

    test('prompts on bookmarkCreated when bookmark exists', () async {
      engagementRepo.state = engagementRepo.state.copyWith(
        listeningCompletions: 0,
        prayerTimesTabVisits: 0,
        bookmarkCreates: 1,
      );
      final bool prompted = await manager.tryPromptIfEligible(
        AppReviewPromptMoment.bookmarkCreated,
      );
      expect(prompted, isTrue);
    });

    test('does not prompt on listening moment without a completion', () async {
      engagementRepo.state = engagementRepo.state.copyWith(
        listeningCompletions: 0,
        prayerTimesTabVisits: 0,
        favoriteAdds: 1,
      );
      final bool prompted = await manager.tryPromptIfEligible(
        AppReviewPromptMoment.listeningSessionCompleted,
      );
      expect(prompted, isFalse);
    });
  });

  group('default production policy', () {
    late AppReviewTriggerManager productionManager;

    setUp(() {
      engagementRepo = MemoryEngagementRepository(
        productionEligibleEngagement(),
      );
      reviewRepo = FakeAppReviewRepository();
      flowGuard = AppReviewFlowGuard();
      productionManager = createTriggerManager(
        engagementRepo: engagementRepo,
        reviewRepo: reviewRepo,
        flowGuard: flowGuard,
      );
    });

    test('prompts with default thresholds after meaningful use', () async {
      final bool prompted = await productionManager.tryPromptIfEligible(
        AppReviewPromptMoment.listeningSessionCompleted,
      );
      expect(prompted, isTrue);
    });

    test('blocks prompt on second app day before minimum app age', () async {
      engagementRepo.state = productionEligibleEngagement().copyWith(
        firstSeenAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      final bool prompted = await productionManager.tryPromptIfEligible(
        AppReviewPromptMoment.listeningSessionCompleted,
      );
      expect(prompted, isFalse);
    });

    test('prompts on leftPrayerTimesTab with two prayer visits', () async {
      engagementRepo.state = productionEligibleEngagement().copyWith(
        listeningCompletions: 0,
        prayerTimesTabVisits: 2,
      );
      final bool prompted = await productionManager.tryPromptIfEligible(
        AppReviewPromptMoment.leftPrayerTimesTab,
      );
      expect(prompted, isTrue);
    });
  });

  group('timing and concurrency', () {
    test('blocks concurrent prompt attempts while one is pending', () async {
      final AppReviewTriggerManager delayedManager = createTriggerManager(
        engagementRepo: engagementRepo,
        reviewRepo: reviewRepo,
        flowGuard: flowGuard,
        policy: const AppReviewTriggerPolicy(
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
  });
}
