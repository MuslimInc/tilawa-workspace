import 'dart:async';
import 'dart:developer' as developer;

import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../entities/app_review_engagement.dart';
import '../entities/app_review_prompt_moment.dart';
import '../entities/app_review_signal.dart';
import '../entities/app_review_trigger_policy.dart';
import '../repositories/app_review_engagement_repository.dart';
import '../usecases/request_app_review_use_case.dart';
import 'app_review_flow_guard.dart';

/// Decides when Tilawa may request a native in-app review.
///
/// Provider-agnostic: delegates the actual dialog to [RequestAppReviewUseCase].
/// All gating is local (SharedPreferences) for MVP.
@lazySingleton
class AppReviewTriggerManager {
  AppReviewTriggerManager(
    this._engagementRepository,
    this._requestReview,
    this._flowGuard,
    this._policy,
  );

  final AppReviewEngagementRepository _engagementRepository;
  final RequestAppReviewUseCase _requestReview;
  final AppReviewFlowGuard _flowGuard;
  final AppReviewTriggerPolicy _policy;

  static const String _logName = 'tilawa.app_review.trigger';

  int _pendingPrompts = 0;

  /// Call when the home shell is ready — never prompts on first launch day alone.
  Future<void> onSessionStarted() async {
    final String dayKey = _dayKey(DateTime.now());
    await _engagementRepository.recordSession(dayKey: dayKey);
    developer.log(
      'session recorded day=$dayKey',
      name: _logName,
    );
  }

  Future<void> recordSignal(AppReviewSignal signal) async {
    final String dayKey = _dayKey(DateTime.now());
    final AppReviewEngagement updated = await _engagementRepository
        .recordSignal(
          signal,
          dayKey: dayKey,
        );
    developer.log(
      'signal=$signal sessions=${updated.sessionCount} '
      'listening=${updated.listeningCompletions}',
      name: _logName,
    );
  }

  /// Evaluates eligibility and may show the OS review dialog after [promptDelay].
  ///
  /// Returns `true` if a prompt was requested (OS may still decline per quota).
  Future<bool> tryPromptIfEligible(AppReviewPromptMoment moment) async {
    if (moment == AppReviewPromptMoment.sessionStarted) {
      return false;
    }
    if (!_policy.allowedPromptMoments.contains(moment)) {
      return false;
    }
    if (_flowGuard.isSacredFlowActive) {
      developer.log(
        'blocked sacred flows=${_flowGuard.activeFlows}',
        name: _logName,
      );
      return false;
    }

    final AppReviewEngagement engagement = await _engagementRepository.load();
    if (!_isEligible(engagement, moment)) {
      developer.log(
        'ineligible moment=$moment sessions=${engagement.sessionCount}',
        name: _logName,
      );
      return false;
    }

    if (_pendingPrompts > 0) {
      return false;
    }
    _pendingPrompts++;

    await Future<void>.delayed(_policy.promptDelay);
    if (_flowGuard.isSacredFlowActive) {
      _pendingPrompts--;
      return false;
    }

    final bool prompted = await _requestNativeReview();
    _pendingPrompts--;
    return prompted;
  }

  bool _isEligible(
    AppReviewEngagement engagement,
    AppReviewPromptMoment moment,
  ) {
    if (engagement.sessionCount < _policy.minSessionCount) {
      return false;
    }
    if (engagement.distinctActiveDays < _policy.minDistinctActiveDays) {
      return false;
    }
    if (!engagement.hasValueMoment) {
      return false;
    }
    if (engagement.listeningCompletions < _policy.minListeningCompletions &&
        engagement.prayerTimesTabVisits < _policy.minPrayerTimesTabVisits &&
        engagement.engagementActions < _policy.minEngagementActions) {
      return false;
    }

    final int? firstSeen = engagement.firstSeenAtMs;
    if (firstSeen == null) {
      return false;
    }
    final Duration appAge = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(firstSeen),
    );
    if (appAge < _policy.minimumAppAgeBeforePrompt) {
      return false;
    }

    if (engagement.promptCount >= _policy.maxLifetimePrompts) {
      return false;
    }

    final int? lastPrompt = engagement.lastPromptAtMs;
    if (lastPrompt != null) {
      final Duration sinceLast = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastPrompt),
      );
      if (sinceLast < _policy.cooldownBetweenPrompts) {
        return false;
      }
    }

    return _momentMatchesThreshold(engagement, moment);
  }

  bool _momentMatchesThreshold(
    AppReviewEngagement engagement,
    AppReviewPromptMoment moment,
  ) {
    return switch (moment) {
      AppReviewPromptMoment.listeningSessionCompleted =>
        engagement.listeningCompletions >= _policy.minListeningCompletions,
      AppReviewPromptMoment.leftPrayerTimesTab =>
        engagement.prayerTimesTabVisits >= _policy.minPrayerTimesTabVisits,
      AppReviewPromptMoment.returnedToRecitersTab => true,
      AppReviewPromptMoment.favoriteReciterAdded =>
        engagement.favoriteAdds >= 1,
      AppReviewPromptMoment.bookmarkCreated => engagement.bookmarkCreates >= 1,
      AppReviewPromptMoment.sessionStarted => false,
    };
  }

  Future<bool> _requestNativeReview() async {
    final result = await _requestReview();
    return result.fold(
      (Failure failure) {
        developer.log(
          'request failed: $failure',
          name: _logName,
          level: 900,
        );
        return false;
      },
      (_) async {
        await _engagementRepository.recordPromptShown(
          shownAtMs: DateTime.now().millisecondsSinceEpoch,
        );
        developer.log('native review requested', name: _logName);
        return true;
      },
    );
  }

  String _dayKey(DateTime time) {
    final String month = time.month.toString().padLeft(2, '0');
    final String day = time.day.toString().padLeft(2, '0');
    return '${time.year}-$month-$day';
  }
}
