/// Display-ready content for the Ayah of the Day widget (spec 041, US2).
///
/// The verse itself ships as pre-rendered PNG artifacts (one per theme) so the
/// native provider shows authentic QCF glyphs without a Dart isolate. Paths
/// point inside the app's own files directory; no user content or location
/// data crosses the bridge (privacy contract of the widget envelope).
class AyahWidgetPayload {
  const AyahWidgetPayload({
    required this.dateKey,
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
    required this.caption,
    required this.imagePathLight,
    required this.imagePathDark,
  });

  /// Local calendar day this selection belongs to (yyyy-MM-dd).
  final String dateKey;

  final int surahNumber;
  final int ayahNumber;

  /// Madinah Mushaf page opened when the widget is tapped.
  final int pageNumber;

  /// Localized reference line, e.g. "سورة البقرة · ١٥٢".
  final String caption;

  /// Absolute paths of the rendered QCF verse artifacts.
  final String imagePathLight;
  final String imagePathDark;

  Map<String, Object?> toJson() => <String, Object?>{
    'dateKey': dateKey,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'pageNumber': pageNumber,
    'caption': caption,
    'imagePathLight': imagePathLight,
    'imagePathDark': imagePathDark,
  };
}
