import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_prompt_moment.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_flow_guard.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_trigger_manager.dart';
import 'package:tilawa/features/app_review/domain/services/prayer_times_app_review_coordinator.dart';
import '../domain/shell_tab_effect.dart';

/// Maps [ShellTabEffect] values to Bloc events and app-review services.
void dispatchShellTabEffects(
  BuildContext context,
  List<ShellTabEffect> effects, {
  required bool Function() isMounted,
}) {
  final AppReviewFlowGuard flowGuard = getIt<AppReviewFlowGuard>();
  final AppReviewTriggerManager reviewTrigger =
      getIt<AppReviewTriggerManager>();
  final PrayerTimesAppReviewCoordinator prayerReviewCoordinator =
      getIt<PrayerTimesAppReviewCoordinator>();

  for (final ShellTabEffect effect in effects) {
    switch (effect) {
      case SyncMainShellTabEffect(:final tabIndex):
        flowGuard.syncMainShellTab(tabIndex);
      case RecordAppReviewSignalEffect(:final signal):
        unawaited(reviewTrigger.recordSignal(signal));
      case TryAppReviewPromptEffect(:final moment):
        unawaited(reviewTrigger.tryPromptIfEligible(moment));
      case StartAppReviewSessionEffect():
        unawaited(reviewTrigger.onSessionStarted());
      case MaybeTryLeftPrayerRecitersPromptEffect():
        if (prayerReviewCoordinator.consumeRecitersPrompt()) {
          unawaited(
            reviewTrigger.tryPromptIfEligible(
              AppReviewPromptMoment.leftPrayerTimesTab,
            ),
          );
        }
      case CancelLeftPrayerRecitersPromptEffect():
        prayerReviewCoordinator.cancelRecitersPrompt();
    }
  }
}
