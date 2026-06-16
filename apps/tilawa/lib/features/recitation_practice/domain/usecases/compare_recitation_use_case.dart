import 'package:injectable/injectable.dart';

import '../entities/recitation_comparison_result.dart';
import '../services/recitation_transcript_scope.dart';
import '../services/recitation_speech_normalizer.dart';
import '../services/recitation_text_aligner.dart';

@lazySingleton
class CompareRecitationUseCase {
  const CompareRecitationUseCase(
    this._speechNormalizer,
    this._aligner,
  );

  final RecitationSpeechNormalizer _speechNormalizer;
  final RecitationTextAligner _aligner;

  /// Strips Latin ASR noise; returns empty when transcript is not Arabic.
  String sanitizeSpokenTranscript(String spokenText) {
    return _speechNormalizer.sanitizeSpokenTranscript(spokenText);
  }

  static const int maxLeadingExtrasForPass = 1;

  /// Normalizes text the same way as spoken/target comparison.
  String normalizeComparisonText(String text) {
    return _speechNormalizer.normalize(text);
  }

  RecitationComparisonResult call({
    required String targetText,
    required String spokenText,
    int maxLeadingExtras = 1000,
  }) {
    final String normalizedTarget = _speechNormalizer.normalize(targetText);
    final String normalizedSpoken = _speechNormalizer.sanitizeSpokenTranscript(
      spokenText,
    );

    final List<String> targetWords = _aligner.tokenize(normalizedTarget);
    final List<String> spokenWords = _aligner.tokenize(normalizedSpoken);

    return _aligner.compare(
      targetWords: targetWords,
      spokenWords: spokenWords,
      spokenText: normalizedSpoken,
      maxLeadingExtras: maxLeadingExtras,
    );
  }

  RecitationComparisonResult callForPass({
    required String targetText,
    required String spokenText,
  }) {
    return call(
      targetText: targetText,
      spokenText: spokenText,
      maxLeadingExtras: maxLeadingExtrasForPass,
    );
  }

  /// Live scoring while the user is still reciting the current ayah.
  ///
  /// Picks the best contiguous target-length window first, then falls back to
  /// [callForLive] so ASR bleed (e.g. ayah-2 words on ayah 1) can still pass.
  RecitationComparisonResult callForLiveScoring({
    required String targetText,
    required String spokenText,
  }) {
    final RecitationComparisonResult? bestSlice = _bestContiguousSliceResult(
      targetText: targetText,
      spokenText: spokenText,
    );
    if (bestSlice != null && bestSlice.score >= passScoreThreshold) {
      return bestSlice;
    }

    final RecitationComparisonResult live = callForLive(
      targetText: targetText,
      spokenText: spokenText,
    );
    if (bestSlice == null || live.score > bestSlice.score) {
      return live;
    }
    return bestSlice;
  }

  static const double passScoreThreshold = 0.8;

  RecitationComparisonResult? _bestContiguousSliceResult({
    required String targetText,
    required String spokenText,
  }) {
    final String normalizedSpoken = _speechNormalizer.sanitizeSpokenTranscript(
      spokenText,
    );
    if (normalizedSpoken.isEmpty) {
      return null;
    }

    final List<String> spokenWords = _aligner.tokenize(normalizedSpoken);
    final List<String> targetWords = _aligner.tokenize(
      _speechNormalizer.normalize(targetText),
    );
    if (spokenWords.isEmpty || targetWords.isEmpty) {
      return null;
    }

    RecitationComparisonResult? best;
    for (var start = 0; start < spokenWords.length; start++) {
      if (!RecitationTranscriptScope.wordsEquivalent(
        spokenWords[start],
        targetWords.first,
      )) {
        continue;
      }

      final int end = start + targetWords.length;
      final String slice = end > spokenWords.length
          ? spokenWords.sublist(start).join(' ')
          : spokenWords.sublist(start, end).join(' ');
      final RecitationComparisonResult result = callForPass(
        targetText: targetText,
        spokenText: slice,
      );
      if (best == null || result.score > best.score) {
        best = result;
      }
    }

    return best;
  }

  /// Allows a few skipped/garbled spoken words between correct ones so ASR
  /// noise (e.g. ayah-2 bleed on ayah 1) does not cap the score at 75%.
  RecitationComparisonResult callForLive({
    required String targetText,
    required String spokenText,
  }) {
    final int targetWordCount = _aligner
        .tokenize(_speechNormalizer.normalize(targetText))
        .length;
    final int maxExtras = targetWordCount.clamp(2, 6);
    return call(
      targetText: targetText,
      spokenText: spokenText,
      maxLeadingExtras: maxExtras,
    );
  }

  int maxLeadingExtrasForLive(String targetText) {
    final int targetWordCount = _aligner
        .tokenize(_speechNormalizer.normalize(targetText))
        .length;
    return targetWordCount.clamp(2, 6);
  }

  bool passes({
    required String targetText,
    required String spokenText,
    required double threshold,
  }) {
    return callForPass(
          targetText: targetText,
          spokenText: spokenText,
        ).score >=
        threshold;
  }

  /// Returns up to [targetText] word count from the first aligned position.
  String? alignmentSliceForTarget({
    required String targetText,
    required String spokenText,
    int maxLeadingExtras = maxLeadingExtrasForPass,
  }) {
    final String normalizedSpoken = _speechNormalizer.sanitizeSpokenTranscript(
      spokenText,
    );
    if (normalizedSpoken.isEmpty) {
      return null;
    }

    final List<String> spokenWords = _aligner.tokenize(normalizedSpoken);
    final List<String> targetWords = _aligner.tokenize(
      _speechNormalizer.normalize(targetText),
    );
    if (spokenWords.isEmpty || targetWords.isEmpty) {
      return null;
    }

    final int maxStart = maxLeadingExtras < spokenWords.length
        ? maxLeadingExtras
        : spokenWords.length - 1;
    for (var start = 0; start <= maxStart; start++) {
      if (!RecitationTranscriptScope.wordsEquivalent(
        spokenWords[start],
        targetWords.first,
      )) {
        continue;
      }

      final int end = start + targetWords.length;
      if (end > spokenWords.length) {
        return spokenWords.sublist(start).join(' ');
      }
      return spokenWords.sublist(start, end).join(' ');
    }

    return null;
  }

  /// Returns the spoken slice that passes [threshold], or null.
  String? extractPassScopedSpoken({
    required String targetText,
    required String spokenText,
    required double threshold,
    int maxLeadingExtras = maxLeadingExtrasForPass,
  }) {
    final String normalizedSpoken = _speechNormalizer.sanitizeSpokenTranscript(
      spokenText,
    );
    if (normalizedSpoken.isEmpty) {
      return null;
    }

    final List<String> spokenWords = _aligner.tokenize(normalizedSpoken);
    if (spokenWords.isEmpty) {
      return null;
    }

    final List<String> targetWords = _aligner.tokenize(
      _speechNormalizer.normalize(targetText),
    );
    if (targetWords.isEmpty) {
      return null;
    }

    final int maxStart = maxLeadingExtras < spokenWords.length
        ? maxLeadingExtras
        : spokenWords.length - 1;
    for (var start = 0; start <= maxStart; start++) {
      if (!RecitationTranscriptScope.wordsEquivalent(
        spokenWords[start],
        targetWords.first,
      )) {
        continue;
      }

      for (var length = targetWords.length; length >= 1; length--) {
        if (start + length > spokenWords.length) {
          continue;
        }
        final String scoped = spokenWords
            .sublist(start, start + length)
            .join(' ');
        if (passes(
          targetText: targetText,
          spokenText: scoped,
          threshold: threshold,
        )) {
          return scoped;
        }
      }
    }

    return null;
  }
}
