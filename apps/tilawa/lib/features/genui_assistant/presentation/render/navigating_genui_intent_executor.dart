import 'package:tilawa/router/app_navigator_keys.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/logger.dart';

import '../../domain/entities/genui_intent.dart';
import 'genui_action_dispatcher.dart';

/// Production executor: routes an allowlisted, already-validated intent to its
/// existing GoRouter destination via the root navigator.
///
/// Deliberately *navigation only*. The AI never performs a high-integrity write
/// (saving a plan, scheduling a reminder) on its own — those intents take the
/// user to the screen that owns the action so they confirm it themselves. This
/// keeps the model a planner, not an actor, and means a mis-issued intent at
/// worst opens a screen.
class NavigatingGenUiIntentExecutor implements GenUiIntentExecutor {
  const NavigatingGenUiIntentExecutor();

  @override
  void execute(GenUiIntent intent) {
    final context = appRootNavigatorKey.currentContext;
    if (context == null) {
      logger.w('[GenUI] no navigator context; intent dropped: $intent');
      return;
    }

    switch (intent) {
      case OpenQuranReaderIntent(:final surah, :final ayah):
        QuranReaderRoute(
          surahNumber: surah,
          ayahNumber: ayah,
        ).push<void>(context);
      case OpenAthkarIntent():
        // Category routing needs the trusted athkar id map; the categories
        // list is the safe, correct destination for now.
        const AthkarCategoriesRoute().push<void>(context);
      case StartTodayWirdIntent():
        const SmartKhatmaHubRoute().push<void>(context);
      case SavePlanIntent():
        // The hub is where a plan is reviewed and saved by the user.
        const SmartKhatmaHubRoute().push<void>(context);
      case SetReminderIntent(:final kind):
        switch (kind) {
          case 'prayer':
            const PrayerNotificationStatusRoute().push<void>(context);
          case 'athkar':
            const AthkarCategoriesRoute().push<void>(context);
          default:
            const SmartKhatmaHubRoute().push<void>(context);
        }
    }
  }
}
