/// Stable [TourTarget] ids for Reciters feature tours.
///
/// Do not rename after release — tied to persisted tour completion keys.
abstract final class RecitersTourTargets {
  static const String searchField = 'reciters_tour_search_field';
  static const String favoritesToggle = 'reciters_tour_favorites_toggle';
  static const String firstReciterCard = 'reciters_tour_first_reciter_card';

  static const String surahSearchField = 'reciters_tour_surah_search_field';
  static const String viewModeToggle = 'reciters_tour_view_mode_toggle';
  static const String playingSurah = 'reciters_tour_playing_surah';
  static const String miniPlayer = 'reciters_tour_mini_player';
}

abstract final class RecitersTourIds {
  static const String intro = 'reciters_intro';
  static const String playback = 'reciter_details_playback';
}
