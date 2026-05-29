import 'package:tilawa/features/app_review/domain/entities/app_review_prompt_moment.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_signal.dart';

/// Side effect produced when the main shell tab or activation state changes.
///
/// [AppShellScreen] and [MainScreen] map these to Bloc events and async work.
sealed class ShellTabEffect {
  const ShellTabEffect();
}

/// Syncs sacred-flow / review guard state with the active tab index.
final class SyncMainShellTabEffect extends ShellTabEffect {
  const SyncMainShellTabEffect(this.tabIndex);

  final int tabIndex;
}

/// Records a review engagement signal (fire-and-forget).
final class RecordAppReviewSignalEffect extends ShellTabEffect {
  const RecordAppReviewSignalEffect(this.signal);

  final AppReviewSignal signal;
}

/// Attempts an in-app review prompt when policy allows.
final class TryAppReviewPromptEffect extends ShellTabEffect {
  const TryAppReviewPromptEffect(this.moment);

  final AppReviewPromptMoment moment;
}

/// Starts the app-review session counter after the shell is shown.
final class StartAppReviewSessionEffect extends ShellTabEffect {
  const StartAppReviewSessionEffect();
}
