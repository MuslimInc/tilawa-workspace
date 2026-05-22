import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_blocked_flow.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_engagement.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_prompt_moment.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_signal.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_trigger_policy.dart';
import 'package:tilawa/features/app_review/domain/repositories/app_review_engagement_repository.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_flow_guard.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_trigger_manager.dart';
import 'package:tilawa/features/app_review/domain/usecases/request_app_review_use_case.dart';
import 'package:tilawa/features/app_review/domain/repositories/app_review_repository.dart';
import 'package:tilawa_core/errors/failures.dart';

class _MemoryEngagementRepo implements AppReviewEngagementRepository {
  AppReviewEngagement state = AppReviewEngagement(
    sessionCount: 5,
    distinctActiveDays: 3,
    listeningCompletions: 2,
    firstSeenAtMs: DateTime.now()
        .subtract(const Duration(days: 10))
        .millisecondsSinceEpoch,
  );

  @override
  Future<AppReviewEngagement> load() async => state;

  @override
  Future<void> save(AppReviewEngagement engagement) async {
    state = engagement;
  }

  @override
  Future<AppReviewEngagement> recordSession({required String dayKey}) async =>
      state;

  @override
  Future<AppReviewEngagement> recordSignal(
    AppReviewSignal signal, {
    required String dayKey,
  }) async =>
      state;

  @override
  Future<AppReviewEngagement> recordPromptShown({required int shownAtMs}) async {
    state = state.copyWith(
      promptCount: state.promptCount + 1,
      lastPromptAtMs: shownAtMs,
    );
    return state;
  }
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
}
