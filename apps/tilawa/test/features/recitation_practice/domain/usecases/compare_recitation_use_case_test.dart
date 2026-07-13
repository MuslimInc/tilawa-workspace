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
    useCase = const CompareRecitationUseCase(
      RecitationSpeechNormalizer(textNormalizer),
      RecitationTextAligner(),
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

    group('Al-Fatiha ASR robustness', () {
      void expectHighScore({
        required String target,
        required String spoken,
        double minScore = 0.95,
      }) {
        final result = useCase(
          targetText: target,
          spokenText: spoken,
        );
        expect(
          result.score,
          greaterThanOrEqualTo(minScore),
          reason: 'spoken: $spoken',
        );
      }

      test('ayah 2 with minor typos and punctuation', () {
        final String target = getVerseNormal(1, 2);
        expectHighScore(
          target: target,
          spoken: 'الحمد لله، رب العالمين؟',
        );
        expectHighScore(
          target: target,
          spoken: 'الحمد لله رب العلمين',
        );
      });

      test('ayah 3 with extra spoken filler', () {
        expectHighScore(
          target: getVerseNormal(1, 3),
          spoken: 'الرحمن و الرحيم',
        );
        expectHighScore(
          target: getVerseNormal(1, 3),
          spoken: 'الرحمان الرحيم',
        );
      });

      test('ayah 4 with collapsed speech', () {
        expectHighScore(
          target: getVerseNormal(1, 4),
          spoken: 'مالكيومالدين',
        );
      });

      test('ayah 5 with hamza variants and extra words', () {
        final String target = getVerseNormal(1, 5);
        expectHighScore(
          target: target,
          spoken: 'اياك نعبد و اياك نستعين',
        );
        expectHighScore(
          target: target,
          spoken: 'إياك نعبد وإياك نستعين man hello',
        );
      });

      test('ayah 6 with ASR spacing noise', () {
        expectHighScore(
          target: getVerseNormal(1, 6),
          spoken: 'اهدنا الصراط المستقيم',
        );
        expectHighScore(
          target: getVerseNormal(1, 6),
          spoken: 'اهدنا و الصراط المستقيم',
        );
      });

      test('ayah 7 with one-word typo stays above 95%', () {
        final String target = getVerseNormal(1, 7);
        final int wordCount = target.split(RegExp(r'\s+')).length;
        final double minScore = (wordCount - 1) / wordCount;

        expectHighScore(
          target: target,
          spoken: 'صراط الذين انعمت عليهم غير المغضوب عليهم ولا الضالين',
          minScore: minScore,
        );
      });

      test('wrong ayah stays below pass threshold', () {
        final result = useCase(
          targetText: getVerseNormal(1, 1),
          spokenText: getVerseNormal(1, 2),
        );

        expect(result.score, lessThan(0.8));
      });

      test('reversed word order does not pass', () {
        final result = useCase(
          targetText: 'بسم الله الرحمن الرحيم',
          spokenText: 'الرحيم الرحمن الله بسم',
        );

        expect(result.score, lessThan(0.8));
      });
    });

    test(
      'extractPassScopedSpoken returns aligned slice from a longer tail',
      () {
        final String? scoped = useCase.extractPassScopedSpoken(
          targetText: getVerseNormal(1, 5),
          spokenText: 'مالك يوم الدين ${getVerseNormal(1, 5)}',
          threshold: 0.8,
          maxLeadingExtras: 12,
        );

        expect(scoped, isNotNull);
        expect(
          useCase.passes(
            targetText: getVerseNormal(1, 5),
            spokenText: scoped!,
            threshold: 0.8,
          ),
          isTrue,
        );
      },
    );

    test('extractPassScopedSpoken rejects tail without a passable slice', () {
      final String? scoped = useCase.extractPassScopedSpoken(
        targetText: getVerseNormal(1, 5),
        spokenText: 'مالك يوم الدين',
        threshold: 0.8,
        maxLeadingExtras: 12,
      );

      expect(scoped, isNull);
    });

    test('extractPassScopedSpoken finds ayah 5 words after ayah 4 tail', () {
      final String? scoped = useCase.extractPassScopedSpoken(
        targetText: getVerseNormal(1, 5),
        spokenText: 'مالك يوم اياك نعبد واياك نستعين',
        threshold: 0.8,
        maxLeadingExtras: 12,
      );

      expect(scoped, isNotNull);
      expect(
        useCase.passes(
          targetText: getVerseNormal(1, 5),
          spokenText: scoped!,
          threshold: 0.8,
        ),
        isTrue,
      );
    });

    test('alignmentSliceForTarget trims trailing ayah words', () {
      final String? slice = useCase.alignmentSliceForTarget(
        targetText: getVerseNormal(1, 3),
        spokenText: 'الرحمن الرحيم مالك يوم الدين اياك نعبد',
      );

      expect(slice, isNotNull);
      expect(slice!.split(RegExp(r'\s+')).length, 2);
      expect(
        useCase
            .callForPass(
              targetText: getVerseNormal(1, 3),
              spokenText: slice,
            )
            .score,
        1.0,
      );
    });

    test('callForLive recovers ayah 1 after ayah-2 ASR bleed', () {
      const String target = 'بسم الله الرحمن الرحيم';
      final result = useCase.callForLiveScoring(
        targetText: target,
        spokenText: 'بسم الله الرحمن العالمين الرحمن الرحيم',
      );

      expect(result.score, greaterThanOrEqualTo(0.8));
    });

    test('callForLiveScoring does not pass ayah 4 on ayah 5 tail', () {
      final result = useCase.callForLiveScoring(
        targetText: getVerseNormal(1, 4),
        spokenText: 'مالك اياك نعبد واياك نستعين',
      );

      expect(result.score, lessThan(0.8));
    });
  });
}
