/// Metadata for a Quran page used for UI overlays.
class PageMetaInfo {
  PageMetaInfo({
    required this.surahNames,
    required this.juzLabel,
    required this.hizbNumber,
  });

  /// The names of the Surahs present on this page.
  final List<String> surahNames;

  /// The label for the Juz' this page belongs to.
  final String juzLabel;

  /// The Hizb number for this page.
  final int hizbNumber;
}
