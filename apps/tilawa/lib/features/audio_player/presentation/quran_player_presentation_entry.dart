import 'package:tilawa/features/audio_player/presentation/player_presentation_controller.dart';

/// Canonical API for opening the expanded Quran player UI.
///
/// All in-app and external entry (notifications, deep links, intents) must call
/// [openExpanded] after playback is ready in [AudioPlayerBloc]. Do not push
/// `/player` or imperative routes directly.
///
/// See `docs/architecture/player-entry-pipeline.md`.
abstract final class QuranPlayerPresentationEntry {
  QuranPlayerPresentationEntry._();

  /// Opens `/player` via push when [hasActiveAudio] is true.
  ///
  /// Returns when the route is popped. No-op if audio is absent or the route is
  /// already open.
  static Future<void> openExpanded({
    required PlayerPresentationController presentation,
    required bool hasActiveAudio,
  }) async {
    if (!hasActiveAudio) {
      return;
    }
    await presentation.expand();
  }
}
