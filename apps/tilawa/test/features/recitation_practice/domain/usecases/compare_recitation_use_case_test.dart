import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/features/recitation_practice/domain/entities/word_match_status.dart';
import 'package:tilawa/features/recitation_practice/domain/services/recitation_text_aligner.dart';
import 'package:tilawa/features/recitation_practice/domain/usecases/compare_recitation_use_case.dart';

void main() {
  late CompareRecitationUseCase useCase;

  setUp(() {
    useCase = CompareRecitationUseCase(
      const TextNormalizationServiceImpl(),
      const RecitationTextAligner(),
    );
  });

  group('CompareRecitationUseCase', () {
    test('scores a perfect Al-Fatiha 1:1 recitation', () {
      const String target = 'بسم الله الرحمن الرحيم';

      final result = useCase(
        targetText: target,
        spokenText: target,
      );

      expect(result.score, 1.0);
      expect(
        result.words.every(
          (word) => word.status == WordMatchStatus.correct,
        ),
        isTrue,
      );
    });

    test('marks missing words for partial recitation', () {
      final result = useCase(
        targetText: 'بسم الله الرحمن الرحيم',
        spokenText: 'بسم الله',
      );

      expect(result.score, closeTo(2 / 4, 0.01));
      expect(result.words.first.status, WordMatchStatus.correct);
      expect(
        result.words.any((word) => word.status == WordMatchStatus.missing),
        isTrue,
      );
    });

    test('returns zero score for empty speech', () {
      final result = useCase(
        targetText: 'بسم الله الرحمن الرحيم',
        spokenText: '   ',
      );

      expect(result.score, 0);
      expect(
        result.words.every(
          (word) => word.status == WordMatchStatus.missing,
        ),
        isTrue,
      );
    });

    test('uses bundled text_normal baseline for ayah lookup', () {
      final String target = getVerseNormal(1, 1);

      final result = useCase(
        targetText: target,
        spokenText: target,
      );

      expect(result.score, 1.0);
    });
  });
}
