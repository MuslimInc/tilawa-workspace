import 'package:tilawa/features/app_review/domain/entities/app_review_prompt_moment.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_signal.dart';

import '../domain/shell_tab_effect.dart';

/// Application orchestration for main-shell tab changes and activation.
///
/// Instantiate per [AppShellScreen] so prayer-load scheduling resets with the
/// shell lifecycle (not a process-wide singleton).
class ShellTabCoordinator {
  ShellTabCoordinator();

  /// Effects to run when the home shell becomes visible for the first time.
  List<ShellTabEffect> onShellActivated(int tabIndex) {
    return <ShellTabEffect>[
      SyncMainShellTabEffect(tabIndex),
      const StartAppReviewSessionEffect(),
    ];
  }

  /// Effects to run when the user changes bottom-nav tabs.
  List<ShellTabEffect> onTabChanged({
    required int previousIndex,
    required int nextIndex,
  }) {
    final List<ShellTabEffect> effects = <ShellTabEffect>[
      SyncMainShellTabEffect(nextIndex),
    ];

    if (previousIndex == 2 && nextIndex != 2) {
      effects.add(
        const RecordAppReviewSignalEffect(
          AppReviewSignal.prayerTimesTabVisited,
        ),
      );
      if (nextIndex == 0) {
        effects.add(
          const TryAppReviewPromptEffect(
            AppReviewPromptMoment.leftPrayerTimesTab,
          ),
        );
      }
    }

    if (previousIndex == 1 && nextIndex == 0) {
      effects.add(
        const TryAppReviewPromptEffect(
          AppReviewPromptMoment.returnedToRecitersTab,
        ),
      );
    }

    return effects;
  }
}
