import 'package:tilawa/features/recitation_practice/domain/entities/recitation_target.dart';

/// Strips earlier-ayah words from a cumulative ASR transcript.
abstract final class RecitationTranscriptScope {
  /// Returns [sanitized] without the words of [targets] before [targetIndex].
  static String activeForTarget({
    required List<RecitationTarget> targets,
    required int targetIndex,
    required String sanitized,
    required String Function(String text) normalize,
  }) {
    if (targetIndex <= 0 || sanitized.trim().isEmpty) {
      return sanitized.trim();
    }

    return activeAfterTargetIndices(
      targets: targets,
      indicesToStrip: List<int>.generate(targetIndex, (int index) => index),
      sanitized: sanitized,
      normalize: normalize,
    );
  }

  /// Returns [sanitized] without the words of [indicesToStrip] ayahs.
  static String activeAfterTargetIndices({
    required List<RecitationTarget> targets,
    required List<int> indicesToStrip,
    required String sanitized,
    required String Function(String text) normalize,
  }) {
    if (sanitized.trim().isEmpty) {
      return '';
    }

    final List<int> sortedIndices = List<int>.from(indicesToStrip)..sort();
    final List<String> prefixWords = <String>[];
    for (final int index in sortedIndices) {
      if (index < 0 || index >= targets.length) {
        continue;
      }
      prefixWords.addAll(_tokenize(normalize(targets[index].normalText)));
    }

    final List<String> spokenWords = _tokenize(normalize(sanitized));
    return stripPrefixWords(spokenWords, prefixWords);
  }

  static List<String> prefixWordsBefore({
    required List<RecitationTarget> targets,
    required int targetIndex,
    required String Function(String text) normalize,
  }) {
    final List<String> words = <String>[];
    for (
      var index = 0;
      index < targetIndex && index < targets.length;
      index++
    ) {
      words.addAll(_tokenize(normalize(targets[index].normalText)));
    }
    return words;
  }

  /// Normalized canonical text for ayahs `0..throughTargetIndex` inclusive.
  static String canonicalPrefixThroughAyahs({
    required List<RecitationTarget> targets,
    required int throughTargetIndex,
    required String Function(String text) normalize,
  }) {
    if (throughTargetIndex < 0) {
      return '';
    }

    final List<String> words = <String>[];
    for (
      var index = 0;
      index <= throughTargetIndex && index < targets.length;
      index++
    ) {
      words.addAll(_tokenize(normalize(targets[index].normalText)));
    }

    return words.join(' ').trim();
  }

  /// Words in [sanitized] after the canonical prefix through [throughTargetIndex].
  static String tailAfterCanonicalPrefix({
    required List<RecitationTarget> targets,
    required int throughTargetIndex,
    required String sanitized,
    required String Function(String text) normalize,
  }) {
    if (sanitized.trim().isEmpty || throughTargetIndex < 0) {
      return sanitized.trim();
    }

    final String canonical = canonicalPrefixThroughAyahs(
      targets: targets,
      throughTargetIndex: throughTargetIndex,
      normalize: normalize,
    );
    if (canonical.isEmpty) {
      return sanitized.trim();
    }

    final List<String> prefixWords = _tokenize(canonical);
    final List<String> spokenWords = _tokenize(normalize(sanitized));
    return stripPrefixWords(spokenWords, prefixWords);
  }

  /// Spoken words consumed after fuzzy-matching [throughTargetIndex] ayahs.
  static String spokenPrefixThroughAyahs({
    required List<RecitationTarget> targets,
    required int throughTargetIndex,
    required String sanitized,
    required String Function(String text) normalize,
  }) {
    if (sanitized.trim().isEmpty || throughTargetIndex < 0) {
      return '';
    }

    final List<String> prefixWords = prefixWordsBefore(
      targets: targets,
      targetIndex: throughTargetIndex + 1,
      normalize: normalize,
    );
    if (prefixWords.isEmpty) {
      return sanitized.trim();
    }

    final List<String> spokenWords = _tokenize(normalize(sanitized));
    final int endSpokenIndex = _endSpokenIndexAfterPrefix(
      spokenWords,
      prefixWords,
    );
    if (endSpokenIndex <= 0) {
      return '';
    }

    return spokenWords.sublist(0, endSpokenIndex).join(' ').trim();
  }

  static int _endSpokenIndexAfterPrefix(
    List<String> spokenWords,
    List<String> prefixWords,
  ) {
    if (prefixWords.isEmpty) {
      return 0;
    }

    var prefixIndex = 0;
    var spokenIndex = 0;

    while (prefixIndex < prefixWords.length &&
        spokenIndex < spokenWords.length) {
      if (_wordsEquivalent(
        spokenWords[spokenIndex],
        prefixWords[prefixIndex],
      )) {
        prefixIndex++;
        spokenIndex++;
        continue;
      }
      spokenIndex++;
    }

    if (prefixIndex < prefixWords.length) {
      return 0;
    }

    return spokenIndex;
  }

  static String stripPrefixWords(
    List<String> spokenWords,
    List<String> prefixWords,
  ) {
    if (prefixWords.isEmpty) {
      return spokenWords.join(' ').trim();
    }

    var prefixIndex = 0;
    var spokenIndex = 0;

    while (prefixIndex < prefixWords.length &&
        spokenIndex < spokenWords.length) {
      if (_wordsEquivalent(
        spokenWords[spokenIndex],
        prefixWords[prefixIndex],
      )) {
        prefixIndex++;
        spokenIndex++;
        continue;
      }
      spokenIndex++;
    }

    if (prefixIndex < prefixWords.length) {
      if (spokenIndex > 0) {
        return spokenWords.sublist(spokenIndex).join(' ').trim();
      }
      return '';
    }

    if (spokenIndex >= spokenWords.length) {
      return '';
    }

    return spokenWords.sublist(spokenIndex).join(' ').trim();
  }

  /// Whether every expected earlier-ayah word was stripped from [sanitized].
  static bool hasFullyStrippedPrefix({
    required String sanitized,
    required List<String> prefixWords,
    required String Function(String text) normalize,
  }) {
    if (prefixWords.isEmpty) {
      return true;
    }

    final List<String> spokenWords = _tokenize(normalize(sanitized));
    return stripPrefixWords(spokenWords, prefixWords).isNotEmpty ||
        _prefixFullyConsumed(spokenWords, prefixWords);
  }

  static bool _prefixFullyConsumed(
    List<String> spokenWords,
    List<String> prefixWords,
  ) {
    var prefixIndex = 0;
    var spokenIndex = 0;

    while (prefixIndex < prefixWords.length &&
        spokenIndex < spokenWords.length) {
      if (_wordsEquivalent(
        spokenWords[spokenIndex],
        prefixWords[prefixIndex],
      )) {
        prefixIndex++;
        spokenIndex++;
        continue;
      }
      spokenIndex++;
    }

    return prefixIndex == prefixWords.length;
  }

  static bool wordsEquivalent(String left, String right) {
    return _wordsEquivalent(left, right);
  }

  static bool _wordsEquivalent(String left, String right) {
    if (left == right) {
      return true;
    }

    final int maxLength = left.length > right.length
        ? left.length
        : right.length;
    if (maxLength <= 2) {
      return false;
    }

    return _editDistance(left, right) <= 1;
  }

  static int _editDistance(String left, String right) {
    final List<int> previousRow = List<int>.generate(
      right.length + 1,
      (int index) => index,
    );
    final List<int> currentRow = List<int>.filled(right.length + 1, 0);

    for (var leftIndex = 0; leftIndex < left.length; leftIndex++) {
      currentRow[0] = leftIndex + 1;
      for (var rightIndex = 0; rightIndex < right.length; rightIndex++) {
        final int substitutionCost =
            left.codeUnitAt(leftIndex) == right.codeUnitAt(rightIndex) ? 0 : 1;
        currentRow[rightIndex + 1] = _min3(
          currentRow[rightIndex] + 1,
          previousRow[rightIndex + 1] + 1,
          previousRow[rightIndex] + substitutionCost,
        );
      }
      for (var index = 0; index < previousRow.length; index++) {
        previousRow[index] = currentRow[index];
      }
    }

    return previousRow[right.length];
  }

  static int _min3(int a, int b, int c) =>
      a < b ? (a < c ? a : c) : (b < c ? b : c);

  static List<String> _tokenize(String text) {
    return text
        .split(RegExp(r'\s+'))
        .map((String word) => word.trim())
        .where((String word) => word.isNotEmpty)
        .toList(growable: false);
  }
}
