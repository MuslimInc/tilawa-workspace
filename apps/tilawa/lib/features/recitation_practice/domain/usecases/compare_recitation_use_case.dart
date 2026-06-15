import 'package:injectable/injectable.dart';

import '../entities/recitation_comparison_result.dart';
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

  RecitationComparisonResult call({
    required String targetText,
    required String spokenText,
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
    );
  }
}
