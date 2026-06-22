import 'package:tilawa_core/logger.dart';

import '../../domain/entities/genui_intent.dart';
import 'genui_action_dispatcher.dart';

/// Diagnostic executor: records the intent without performing navigation.
///
/// Kept as a test/QA double and an opt-out. Production wires
/// `NavigatingGenUiIntentExecutor` via the DI module; swapping between the two
/// changes no other layer because the dispatcher only ever speaks in typed
/// intents.
class LoggingGenUiIntentExecutor implements GenUiIntentExecutor {
  const LoggingGenUiIntentExecutor();

  @override
  void execute(GenUiIntent intent) {
    final String label = switch (intent) {
      OpenQuranReaderIntent(:final surah, :final ayah) =>
        'openQuranReader(surah: $surah, ayah: $ayah)',
      StartTodayWirdIntent(:final planId) => 'startTodayWird(planId: $planId)',
      OpenAthkarIntent(:final category) => 'openAthkar(category: $category)',
      SetReminderIntent(:final kind, :final hour, :final minute) =>
        'setReminder(kind: $kind, $hour:$minute)',
      SavePlanIntent(:final planDraftId) => 'savePlan(draft: $planDraftId)',
    };
    logger.i('[GenUI] intent dispatched: $label');
  }
}
