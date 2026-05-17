/// Stable Semantics identifiers for the Reciters feature.
///
/// These values are referenced by Maestro E2E flows
/// (`.maestro/reciters_*.yaml`). They must never change without updating
/// the corresponding flow files, because Maestro targets them by exact string
/// match via the Flutter Semantics tree.
///
/// Usage in widgets:
/// ```dart
/// Semantics(
///   identifier: ReciterSemanticsIds.recitersTab,
///   child: ...,
/// )
/// ```
///
/// Usage in Maestro YAML:
/// ```yaml
/// - tapOn:
///     id: "reciters_tab"
/// ```
abstract final class ReciterSemanticsIds {
  // ── Navigation ──────────────────────────────────────────────────────────────

  /// Bottom-nav / side-rail item that opens the Reciters screen.
  static const String recitersTab = 'reciters_tab';

  // ── Reciters list screen ─────────────────────────────────────────────────────

  /// Search text field in the Reciters screen header bar.
  static const String recitersSearchField = 'reciters_search_field';

  /// Heart / favourites filter toggle button in the Reciters screen header.
  static const String recitersFavoritesToggle = 'reciters_favorites_toggle';

  /// Letter-index toggle in the Reciters screen header bar.
  static const String recitersLetterIndexToggle =
      'reciters_letter_index_toggle';

  /// Overflow menu for secondary Reciters header actions.
  static const String recitersMoreActionsButton = 'reciters_more_actions_button';

  // ── Reciter cards (dynamic, per reciter) ────────────────────────────────────

  /// Tappable card for a specific reciter.
  /// [id] is the reciter's numeric identifier from the API.
  static String reciterCard(int id) => 'reciter_card_$id';

  /// Favourite heart button on an individual reciter card.
  /// [id] is the reciter's numeric identifier from the API.
  static String reciterFavoriteButton(int id) => 'reciter_favorite_button_$id';

  // ── Reciter details screen ───────────────────────────────────────────────────

  /// Surah-filter search field pinned at the top of the Reciter Details screen.
  static const String reciterDetailsSurahSearch =
      'reciter_details_surah_search';

  /// Toggle button that switches between list and grid view in Reciter Details.
  static const String reciterDetailsViewToggle = 'reciter_details_view_toggle';

  // ── Download All button (Reciter Details screen) ─────────────────────────────

  /// "Download All" button in the idle / ready-to-download state.
  static const String reciterDetailsDownloadAllIdle =
      'reciter_details_download_all_idle';

  /// "Download All" button while a batch download is in progress.
  static const String reciterDetailsDownloadAllDownloading =
      'reciter_details_download_all_downloading';

  /// "All downloaded" badge shown when every surah is already downloaded.
  static const String reciterDetailsDownloadAllCompleted =
      'reciter_details_download_all_completed';

  // ── Per-surah download buttons ────────────────────────────────────────────────

  /// Download button for an individual surah.
  /// [surahId] is [SurahEntity.formattedId] (e.g. "001") or a fallback index.
  static String surahDownloadButton(String surahId) =>
      'surah_download_button_$surahId';
}
