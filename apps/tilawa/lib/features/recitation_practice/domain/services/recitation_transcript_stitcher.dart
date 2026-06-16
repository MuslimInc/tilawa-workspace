/// Stitches ASR segments from separate listen sessions into one transcript.
abstract final class RecitationTranscriptStitcher {
  /// Extends the current partial within one listen session.
  static String extendPartial(String current, String incoming) {
    final String trimmedIncoming = incoming.trim();
    if (trimmedIncoming.isEmpty) {
      return current.trim();
    }
    final String trimmedCurrent = current.trim();
    if (trimmedCurrent.isEmpty) {
      return trimmedIncoming;
    }
    if (trimmedIncoming.startsWith(trimmedCurrent)) {
      return trimmedIncoming;
    }
    if (trimmedCurrent.startsWith(trimmedIncoming)) {
      return trimmedCurrent;
    }
    return stitch(trimmedCurrent, trimmedIncoming);
  }

  /// Joins committed and live segments across listen restarts.
  static String stitch(String base, String segment) {
    final String left = base.trim();
    final String right = segment.trim();
    if (right.isEmpty) {
      return left;
    }
    if (left.isEmpty) {
      return right;
    }
    if (left == right) {
      return left;
    }
    if (right.startsWith(left)) {
      return right;
    }
    if (left.startsWith(right)) {
      return left;
    }
    if (left.contains(right)) {
      return left;
    }
    if (right.contains(left)) {
      return right;
    }

    final List<String> leftWords = _tokenize(left);
    final List<String> rightWords = _tokenize(right);
    final int maxOverlap = leftWords.length < rightWords.length
        ? leftWords.length
        : rightWords.length;

    for (var overlap = maxOverlap; overlap > 0; overlap--) {
      final String leftSuffix = leftWords
          .sublist(leftWords.length - overlap)
          .join(' ');
      final String rightPrefix = rightWords.sublist(0, overlap).join(' ');
      if (leftSuffix == rightPrefix) {
        return <String>[
          ...leftWords,
          ...rightWords.sublist(overlap),
        ].join(' ');
      }
    }

    return '$left $right';
  }

  static List<String> _tokenize(String text) {
    return text
        .split(RegExp(r'\s+'))
        .map((String word) => word.trim())
        .where((String word) => word.isNotEmpty)
        .toList(growable: false);
  }
}
