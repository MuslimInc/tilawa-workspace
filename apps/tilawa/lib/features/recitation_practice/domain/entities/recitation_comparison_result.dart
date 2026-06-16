import 'package:equatable/equatable.dart';

import 'compared_word.dart';
import 'word_match_status.dart';

/// Outcome of comparing spoken text against a target ayah.
class RecitationComparisonResult extends Equatable {
  const RecitationComparisonResult({
    required this.words,
    required this.score,
    required this.spokenText,
  });

  final List<ComparedWord> words;

  /// Fraction of target words matched correctly, from 0.0 to 1.0.
  final double score;
  final String spokenText;

  int get correctCount =>
      words.where((word) => word.status == WordMatchStatus.correct).length;

  @override
  List<Object?> get props => [words, score, spokenText];
}
