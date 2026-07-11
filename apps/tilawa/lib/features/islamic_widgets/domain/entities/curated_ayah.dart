/// A Quran verse approved for the daily home-screen widget rotation.
class CuratedAyah {
  const CuratedAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
  }) : assert(surahNumber >= 1 && surahNumber <= 114),
       assert(ayahNumber >= 1),
       assert(pageNumber >= 1 && pageNumber <= 604);

  /// The Surah number in Mushaf order.
  final int surahNumber;

  /// The verse number within [surahNumber].
  final int ayahNumber;

  /// The Madinah Mushaf page opened when the widget is tapped.
  final int pageNumber;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CuratedAyah &&
          surahNumber == other.surahNumber &&
          ayahNumber == other.ayahNumber &&
          pageNumber == other.pageNumber;

  @override
  int get hashCode => Object.hash(surahNumber, ayahNumber, pageNumber);
}
