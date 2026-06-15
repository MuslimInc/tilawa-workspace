import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/features/recitation_practice/domain/entities/word_match_status.dart';
import 'package:tilawa/features/recitation_practice/domain/services/recitation_speech_normalizer.dart';
import 'package:tilawa/features/recitation_practice/domain/services/recitation_text_aligner.dart';
import 'package:tilawa/features/recitation_practice/domain/usecases/compare_recitation_use_case.dart';

void main() {
  late CompareRecitationUseCase useCase;

  setUp(() {
    const TextNormalizationServiceImpl textNormalizer =
        TextNormalizationServiceImpl();
    useCase = CompareRecitationUseCase(
      RecitationSpeechNormalizer(textNormalizer),
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

    test('matches Uthmani display text against diacritic-free speech', () {
      final String uthmani = getVerse(1, 1);
      const String asr = 'بسم الله الرحمن الرحيم';

      final result = useCase(
        targetText: uthmani,
        spokenText: asr,
      );

      expect(result.score, 1.0);
    });

    test('matches speech without word spaces', () {
      final result = useCase(
        targetText: 'بسم الله الرحمن الرحيم',
        spokenText: 'بسماللهالرحمنالرحيم',
      );

      expect(result.score, 1.0);
    });

    test('matches Allah ligature from speech recognition', () {
      final result = useCase(
        targetText: 'بسم الله الرحمن الرحيم',
        spokenText: 'بسم \uFDF2 الرحمن الرحيم',
      );

      expect(result.score, 1.0);
    });

    test('ignores English ASR noise mixed with Arabic', () {
      final result = useCase(
        targetText: 'بسم الله الرحمن الرحيم',
        spokenText: 'بسم الله الرحمن الرحيم man you are a man',
      );

      expect(result.score, 1.0);
    });

    test('returns zero score for English-only transcript', () {
      final result = useCase(
        targetText: 'بسم الله الرحمن الرحيم',
        spokenText: "man you're a man",
      );

      expect(result.score, 0);
    });
  });
}
