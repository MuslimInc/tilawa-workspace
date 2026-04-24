/// Metadata for a single word within a Quran line block.
class QuranWordMetadata {
  const QuranWordMetadata({
    required this.surah,
    required this.verse,
    required this.startOffset,
    required this.endOffset,
  });

  /// The surah number (1-114).
  final int surah;

  /// The verse number (1-indexed).
  final int verse;

  /// The start character offset in the parent TextSpan.
  final int startOffset;

  /// The end character offset (exclusive) in the parent TextSpan.
  final int endOffset;
}
