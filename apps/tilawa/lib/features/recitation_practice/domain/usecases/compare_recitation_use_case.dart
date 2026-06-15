import 'package:injectable/injectable.dart';
import 'package:quran_qcf/quran_qcf.dart';

import '../entities/recitation_comparison_result.dart';
import '../services/recitation_text_aligner.dart';

@lazySingleton
class CompareRecitationUseCase {
  const CompareRecitationUseCase(
    this._textNormalizer,
    this._aligner,
  );

  final TextNormalizationService _textNormalizer;
  final RecitationTextAligner _aligner;

  RecitationComparisonResult call({
    required String targetText,
    required String spokenText,
  }) {
    final String normalizedTarget = _textNormalizer.normalise(targetText);
    final String normalizedSpoken = _textNormalizer.normalise(spokenText);

    final List<String> targetWords = _aligner.tokenize(normalizedTarget);
    final List<String> spokenWords = _aligner.tokenize(normalizedSpoken);

    return _aligner.compare(
      targetWords: targetWords,
      spokenWords: spokenWords,
      spokenText: spokenText.trim(),
    );
  }
}
