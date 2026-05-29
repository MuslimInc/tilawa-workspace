/// Stable Semantics identifiers for the Quran Player feature.
///
/// These values are referenced by Maestro E2E flows under `.maestro/quran_player/`
/// and `.maestro/quran_player.yaml`. They must never change without updating
/// the corresponding flow files, because Maestro targets them by exact string
/// match via the Flutter Semantics tree.
///
/// Usage in widgets:
/// ```dart
/// Semantics(
///   identifier: QuranPlayerSemanticsIds.miniPlayer,
///   child: ...,
/// )
/// ```
///
/// Usage in Maestro YAML:
/// ```yaml
/// - tapOn:
///     id: "quran_player_mini"
/// ```
abstract final class QuranPlayerSemanticsIds {
  // ── Mini player (collapsed) ─────────────────────────────────────────────────

  /// Root tap target of the collapsed mini-player bar.
  /// Tapping it expands the player to the full-screen sheet.
  static const String miniPlayer = 'quran_player_mini';

  /// Mini-player play/pause button.
  static const String miniPlayerPlayPause = 'quran_player_mini_play_pause';

  /// Mini-player dismiss (close) button.
  static const String miniPlayerClose = 'quran_player_mini_close';

  // ── Expanded player chrome ──────────────────────────────────────────────────

  /// Chevron-down button in the expanded player header. Collapses the player.
  static const String expandedCollapseButton = 'quran_player_collapse';

  /// More-vertical (overflow) button in the expanded player header.
  /// Opens the actions bottom sheet (sleep timer / background / stop).
  static const String expandedMoreMenu = 'quran_player_more_menu';

  /// Track title text on the expanded player (used as a "player is expanded"
  /// sentinel — its presence behind a dialog proves the player wasn't hidden).
  static const String expandedTrackTitle = 'quran_player_track_title';

  /// Track artist text on the expanded player.
  static const String expandedTrackArtist = 'quran_player_track_artist';

  /// Background artwork area on the expanded player.
  static const String expandedArtwork = 'quran_player_artwork';

  // ── Expanded player transport row ───────────────────────────────────────────

  /// Shuffle toggle.
  static const String transportShuffle = 'quran_player_shuffle';

  /// Skip-to-previous button.
  static const String transportPrevious = 'quran_player_previous';

  /// Center play/pause button on the expanded player.
  static const String transportPlayPause = 'quran_player_play_pause';

  /// Skip-to-next button.
  static const String transportNext = 'quran_player_next';

  /// Repeat-mode cycle button (none → all → one → none).
  static const String transportRepeat = 'quran_player_repeat';

  // ── Expanded player progress / seek bar ─────────────────────────────────────

  /// Seek slider for the playing track.
  static const String progressSeekBar = 'quran_player_seek';

  /// Current-position label below the seek bar.
  static const String progressPosition = 'quran_player_position';

  /// Total-duration label below the seek bar.
  static const String progressDuration = 'quran_player_duration';

  // ── Expanded player action pills ────────────────────────────────────────────

  /// Playback speed pill (label: "1.0x" etc.). Opens the speed slider dialog.
  static const String actionPillSpeed = 'quran_player_pill_speed';

  /// Volume pill (speaker icon). Opens the volume slider dialog.
  static const String actionPillVolume = 'quran_player_pill_volume';

  /// Sleep timer pill (timer icon). Opens the sleep timer dialog.
  /// Only present when sleep timer is enabled in settings.
  static const String actionPillSleepTimer = 'quran_player_pill_sleep_timer';

  // ── Slider dialog (volume / speed) ──────────────────────────────────────────

  /// Root container of the slider dialog (used as a presence sentinel).
  static const String sliderDialog = 'quran_player_slider_dialog';

  /// The slider control inside the slider dialog.
  static const String sliderDialogSlider = 'quran_player_slider_dialog_slider';

  /// The current-value label inside the slider dialog.
  static const String sliderDialogValue = 'quran_player_slider_dialog_value';

  // ── Expanded player overflow sheet ──────────────────────────────────────────

  /// Sleep-timer row in the expanded player overflow bottom sheet.
  static const String menuSheetSleepTimer = 'quran_player_menu_sleep_timer';

  /// Background-source row in the expanded player overflow bottom sheet.
  static const String menuSheetBackground = 'quran_player_menu_background';

  /// Stop-playback row in the expanded player overflow bottom sheet.
  static const String menuSheetStop = 'quran_player_menu_stop';

  // ── Sleep timer dialog ──────────────────────────────────────────────────────

  /// Root container of the sleep timer dialog.
  static const String sleepTimerDialog = 'quran_player_sleep_timer_dialog';

  /// 15-minutes preset chip.
  static const String sleepTimer15 = 'quran_player_sleep_timer_15';

  /// 30-minutes preset chip.
  static const String sleepTimer30 = 'quran_player_sleep_timer_30';

  /// 60-minutes preset chip.
  static const String sleepTimer60 = 'quran_player_sleep_timer_60';

  /// "End of track" chip.
  static const String sleepTimerEndOfTrack =
      'quran_player_sleep_timer_end_of_track';

  /// Custom-duration chip (opens a duration picker).
  static const String sleepTimerCustom = 'quran_player_sleep_timer_custom';

  /// Cancel-active-timer button (only present when a timer is running).
  static const String sleepTimerCancel = 'quran_player_sleep_timer_cancel';

  /// Close button (only present when no timer is active).
  static const String sleepTimerClose = 'quran_player_sleep_timer_close';

  // ── Background source dialog ────────────────────────────────────────────────

  /// Root container of the background-source dialog.
  static const String backgroundSourceDialog =
      'quran_player_background_source_dialog';

  /// "Pick from gallery" row.
  static const String backgroundSourceGallery =
      'quran_player_background_source_gallery';

  /// "Take a photo" row.
  static const String backgroundSourceCamera =
      'quran_player_background_source_camera';

  /// "Reset to default" row (only present when a custom background is set).
  static const String backgroundSourceReset =
      'quran_player_background_source_reset';

  /// Close button on the background-source dialog.
  static const String backgroundSourceClose =
      'quran_player_background_source_close';

  // ── Queue ───────────────────────────────────────────────────────────────────

  /// Bottom-sheet "queue" section on the expanded player.
  static const String queueSheet = 'quran_player_queue_sheet';

  /// Drag handle that resizes the queue sheet between peek and full height.
  static const String queueSheetHandle = 'quran_player_queue_handle';

  /// Hint shown when the queue sheet is collapsed (peek height).
  static const String queueSheetExpandHint = 'quran_player_queue_expand_hint';

  /// Tappable queue track tile.
  /// [audioId] is [AudioEntity.id] (typically a stable surah id).
  static String queueItem(String audioId) => 'quran_player_queue_item_$audioId';
}
