import '../entities/compared_word.dart';
import '../entities/recitation_comparison_result.dart';
import '../entities/word_match_status.dart';

/// Aligns spoken words to a target ayah and computes a score.
class RecitationTextAligner {
  const RecitationTextAligner();

  RecitationComparisonResult compare({
    required List<String> targetWords,
    required List<String> spokenWords,
    required String spokenText,
  }) {
    if (targetWords.isEmpty) {
      return RecitationComparisonResult(
        words: const <ComparedWord>[],
        score: 0,
        spokenText: spokenText,
      );
    }

    final List<String> resolvedSpokenWords = _resolveSpokenWords(
      spokenText: spokenText,
      spokenWords: spokenWords,
      targetWords: targetWords,
    );

    final List<ComparedWord> alignedWords = <ComparedWord>[];
    var spokenIndex = 0;
    var correctCount = 0;

    for (final String targetWord in targetWords) {
      if (spokenIndex < resolvedSpokenWords.length &&
          _wordsMatch(targetWord, resolvedSpokenWords[spokenIndex])) {
        alignedWords.add(
          ComparedWord(word: targetWord, status: WordMatchStatus.correct),
        );
        correctCount++;
        spokenIndex++;
        continue;
      }

      alignedWords.add(
        ComparedWord(word: targetWord, status: WordMatchStatus.missing),
      );
    }

    final double score = correctCount / targetWords.length;
    return RecitationComparisonResult(
      words: alignedWords,
      score: score,
      spokenText: spokenText,
    );
  }

  List<String> tokenize(String text) {
    return text
        .split(RegExp(r'\s+'))
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _resolveSpokenWords({
    required String spokenText,
    required List<String> spokenWords,
    required List<String> targetWords,
  }) {
    if (spokenWords.length > 1 || targetWords.length <= 1) {
      return spokenWords;
    }

    final String collapsed = spokenText.replaceAll(RegExp(r'\s+'), '');
    if (collapsed.isEmpty) {
      return spokenWords;
    }

    final List<String> segmented = _segmentByTargetWords(
      collapsed,
      targetWords,
    );
    if (segmented.length == targetWords.length) {
      return segmented;
    }

    return spokenWords;
  }

  List<String> _segmentByTargetWords(
    String spoken,
    List<String> targetWords,
  ) {
    final List<String> segments = <String>[];
    var index = 0;

    for (final String targetWord in targetWords) {
      if (index >= spoken.length) {
        return const <String>[];
      }

      final int maxLength = spoken.length - index;
      final int sliceLength = targetWord.length <= maxLength
          ? targetWord.length
          : maxLength;
      final String slice = spoken.substring(index, index + sliceLength);

      if (!_wordsMatch(slice, targetWord)) {
        return const <String>[];
      }

      segments.add(slice);
      index += sliceLength;
    }

    if (index != spoken.length) {
      return const <String>[];
    }

    return segments;
  }

  bool _wordsMatch(String left, String right) {
    if (left == right) {
      return true;
    }
    if (left.length <= 2 || right.length <= 2) {
      return false;
    }
    return _editDistance(left, right) <= 1;
  }

  int _editDistance(String left, String right) {
    final List<int> previousRow = List<int>.generate(
      right.length + 1,
      (index) => index,
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

  int _min3(int a, int b, int c) => a < b ? (a < c ? a : c) : (b < c ? b : c);
}
