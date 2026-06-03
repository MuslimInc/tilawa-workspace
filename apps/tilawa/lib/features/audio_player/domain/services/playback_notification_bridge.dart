/// Bridges Android media-notification gestures to app-level playback UI.
///
/// Wired during [AppStartupTasks.initializeAudioService] so the handler layer
/// stays free of [getIt] / [BuildContext].
abstract final class PlaybackNotificationBridge {
  PlaybackNotificationBridge._();

  /// Fired when the user taps the playback notification body (media button).
  static void Function()? onContentTap;

  static void notifyContentTap() => onContentTap?.call();
}
