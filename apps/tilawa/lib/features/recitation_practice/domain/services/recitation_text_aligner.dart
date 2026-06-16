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
    int maxLeadingExtras = 1000,
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

    final List<String> boundedSpokenWords = _boundLeadingSpokenWords(
      targetWords: targetWords,
      spokenWords: resolvedSpokenWords,
      maxLeadingExtras: maxLeadingExtras,
    );

    final int firstMatchIndex = _indexOfFirstTargetMatch(
      targetWords: targetWords,
      spokenWords: boundedSpokenWords,
    );
    if (firstMatchIndex > maxLeadingExtras) {
      return RecitationComparisonResult(
        words: List<ComparedWord>.generate(
          targetWords.length,
          (int index) => ComparedWord(
            word: targetWords[index],
            status: WordMatchStatus.missing,
          ),
        ),
        score: 0,
        spokenText: spokenText,
      );
    }

    final List<ComparedWord> alignedWords = _alignToTarget(
      targetWords: targetWords,
      spokenWords: boundedSpokenWords,
    );

    final int correctCount = alignedWords
        .where((ComparedWord word) => word.status == WordMatchStatus.correct)
        .length;
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

  List<String> _boundLeadingSpokenWords({
    required List<String> targetWords,
    required List<String> spokenWords,
    required int maxLeadingExtras,
  }) {
    if (spokenWords.length <= targetWords.length + maxLeadingExtras) {
      return spokenWords;
    }
    return spokenWords
        .sublist(0, targetWords.length + maxLeadingExtras)
        .toList(growable: false);
  }

  int _indexOfFirstTargetMatch({
    required List<String> targetWords,
    required List<String> spokenWords,
  }) {
    if (targetWords.isEmpty || spokenWords.isEmpty) {
      return 0;
    }

    for (var spokenIndex = 0; spokenIndex < spokenWords.length; spokenIndex++) {
      if (_wordsMatch(spokenWords[spokenIndex], targetWords.first)) {
        return spokenIndex;
      }
    }

    return spokenWords.length;
  }

  List<String> _resolveSpokenWords({
    required String spokenText,
    required List<String> spokenWords,
    required List<String> targetWords,
  }) {
    if (targetWords.length <= 1) {
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

  List<ComparedWord> _alignToTarget({
    required List<String> targetWords,
    required List<String> spokenWords,
  }) {
    final int targetCount = targetWords.length;
    final int spokenCount = spokenWords.length;

    if (targetCount == 0) {
      return const <ComparedWord>[];
    }

    final List<List<int>> scores = List<List<int>>.generate(
      targetCount + 1,
      (_) => List<int>.filled(spokenCount + 1, 0),
    );
    final List<List<int>> directions = List<List<int>>.generate(
      targetCount + 1,
      (_) => List<int>.filled(spokenCount + 1, 0),
    );

    for (var targetIndex = 1; targetIndex <= targetCount; targetIndex++) {
      scores[targetIndex][0] = scores[targetIndex - 1][0];
      directions[targetIndex][0] = 1;
    }
    for (var spokenIndex = 1; spokenIndex <= spokenCount; spokenIndex++) {
      scores[0][spokenIndex] = scores[0][spokenIndex - 1];
      directions[0][spokenIndex] = 2;
    }

    for (var targetIndex = 1; targetIndex <= targetCount; targetIndex++) {
      for (var spokenIndex = 1; spokenIndex <= spokenCount; spokenIndex++) {
        var bestScore = scores[targetIndex - 1][spokenIndex];
        var direction = 1;

        final int skipSpokenScore = scores[targetIndex][spokenIndex - 1];
        if (skipSpokenScore > bestScore) {
          bestScore = skipSpokenScore;
          direction = 2;
        }

        final String targetWord = targetWords[targetIndex - 1];
        final String spokenWord = spokenWords[spokenIndex - 1];
        if (_wordsMatch(targetWord, spokenWord)) {
          final int matchScore = scores[targetIndex - 1][spokenIndex - 1] + 1;
          if (matchScore >= bestScore) {
            bestScore = matchScore;
            direction = 0;
          }
        }

        scores[targetIndex][spokenIndex] = bestScore;
        directions[targetIndex][spokenIndex] = direction;
      }
    }

    final List<WordMatchStatus> statuses = List<WordMatchStatus>.filled(
      targetCount,
      WordMatchStatus.missing,
    );

    var targetIndex = targetCount;
    var spokenIndex = spokenCount;
    while (targetIndex > 0) {
      switch (directions[targetIndex][spokenIndex]) {
        case 0:
          statuses[targetIndex - 1] = WordMatchStatus.correct;
          targetIndex--;
          spokenIndex--;
        case 1:
          targetIndex--;
        case 2:
          spokenIndex--;
        default:
          targetIndex--;
      }
    }

    return List<ComparedWord>.generate(
      targetCount,
      (int index) => ComparedWord(
        word: targetWords[index],
        status: statuses[index],
      ),
    );
  }

  bool _wordsMatch(String left, String right) {
    if (left == right) {
      return true;
    }

    final int maxLength = left.length > right.length
        ? left.length
        : right.length;
    if (maxLength == 0) {
      return true;
    }
    if (maxLength <= 2) {
      return false;
    }

    final int allowedDistance = _allowedEditDistance(maxLength);
    return _editDistance(left, right) <= allowedDistance;
  }

  int _allowedEditDistance(int wordLength) {
    if (wordLength <= 4) {
      return 1;
    }
    if (wordLength <= 8) {
      return 2;
    }
    return 3;
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
