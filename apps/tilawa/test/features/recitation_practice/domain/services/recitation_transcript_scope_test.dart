import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/features/recitation_practice/domain/entities/recitation_target.dart';
import 'package:tilawa/features/recitation_practice/domain/services/recitation_speech_normalizer.dart';
import 'package:tilawa/features/recitation_practice/domain/services/recitation_text_aligner.dart';
import 'package:tilawa/features/recitation_practice/domain/services/recitation_transcript_scope.dart';
import 'package:tilawa/features/recitation_practice/domain/usecases/compare_recitation_use_case.dart';

void main() {
  final CompareRecitationUseCase compare = CompareRecitationUseCase(
    const RecitationSpeechNormalizer(TextNormalizationServiceImpl()),
    const RecitationTextAligner(),
  );

  String normalize(String text) => compare.normalizeComparisonText(text);

  const List<RecitationTarget> targets = <RecitationTarget>[
    RecitationTarget(
      surahNumber: 1,
      ayahNumber: 1,
      pageNumber: 1,
      displayText: 'بِسْمِ اللَّهِ',
      normalText: 'بسم الله الرحمن الرحيم',
    ),
    RecitationTarget(
      surahNumber: 1,
      ayahNumber: 2,
      pageNumber: 1,
      displayText: 'الْحَمْدُ',
      normalText: 'الحمد لله رب العالمين',
    ),
    RecitationTarget(
      surahNumber: 1,
      ayahNumber: 3,
      pageNumber: 1,
      displayText: 'الرَّحْمَٰنِ',
      normalText: 'الرحمن الرحيم',
    ),
  ];

  group('RecitationTranscriptScope', () {
    test('strips earlier ayah words for the active target', () {
      const String cumulative =
          'بسم الله الرحمن الرحيم الحمد لله رب العالمين الرحمن';

      expect(
        RecitationTranscriptScope.activeForTarget(
          targets: targets,
          targetIndex: 2,
          sanitized: cumulative,
          normalize: normalize,
        ),
        'الرحمن',
      );
    });

    test('returns empty when earlier ayahs are not fully present', () {
      expect(
        RecitationTranscriptScope.activeForTarget(
          targets: targets,
          targetIndex: 2,
          sanitized: 'بسم الله الرحمن الرحيم',
          normalize: normalize,
        ),
        '',
      );
    });

    test('strips ayah 1 when ASR uses alef maksura for ya', () {
      const String cumulative = 'بسم الله الرحمن الرحىم الحمد لله رب العالمين';

      expect(
        RecitationTranscriptScope.activeForTarget(
          targets: targets,
          targetIndex: 1,
          sanitized: cumulative,
          normalize: normalize,
        ),
        'الحمد لله رب العالمىن',
      );
    });

    test('activeAfterTargetIndices strips only selected ayahs', () {
      const String cumulative =
          'بسم الله الرحمن الرحيم الحمد لله رب العالمين يوم الدين اياك نعبد';

      expect(
        RecitationTranscriptScope.activeAfterTargetIndices(
          targets: targets,
          indicesToStrip: const <int>[0, 1],
          sanitized: cumulative,
          normalize: normalize,
        ),
        'ىوم الدىن اىاك نعبد',
      );
    });

    test('does not treat ayah 1 tail as ayah 3 for pass checks', () {
      final bool passes = compare.passes(
        targetText: targets[2].normalText,
        spokenText: 'بسم الله الرحمن الرحيم',
        threshold: 0.8,
      );

      expect(passes, isFalse);
    });

    test('canonicalPrefixThroughAyahs joins normalized ayah text', () {
      expect(
        RecitationTranscriptScope.canonicalPrefixThroughAyahs(
          targets: targets,
          throughTargetIndex: 0,
          normalize: normalize,
        ),
        'بسم الله الرحمن الرحىم',
      );
      expect(
        RecitationTranscriptScope.canonicalPrefixThroughAyahs(
          targets: targets,
          throughTargetIndex: 1,
          normalize: normalize,
        ),
        'بسم الله الرحمن الرحىم الحمد لله رب العالمىن',
      );
    });

    test('tailAfterCanonicalPrefix returns only speech after ayah 1', () {
      const String cumulative = 'بسم الله الرحمن الرحىم رب العالمين';

      expect(
        RecitationTranscriptScope.tailAfterCanonicalPrefix(
          targets: targets,
          throughTargetIndex: 0,
          sanitized: cumulative,
          normalize: normalize,
        ),
        'رب العالمىن',
      );
    });

    test('tailAfterCanonicalPrefix is empty when only ayah 1 is present', () {
      expect(
        RecitationTranscriptScope.tailAfterCanonicalPrefix(
          targets: targets,
          throughTargetIndex: 0,
          sanitized: 'بسم الله الرحمن الرحىم',
          normalize: normalize,
        ),
        '',
      );
    });

    test('ayah 3 pass in tail mid-stream is not at tail start', () {
      const String tail = 'نربى العالمىن الرحمن الرحىم';

      expect(
        compare.extractPassScopedSpoken(
          targetText: targets[2].normalText,
          spokenText: tail,
          threshold: 0.8,
          maxLeadingExtras: 0,
        ),
        isNull,
      );
      expect(
        compare.extractPassScopedSpoken(
          targetText: targets[2].normalText,
          spokenText: 'الرحمن الرحيم',
          threshold: 0.8,
          maxLeadingExtras: 0,
        ),
        isNotNull,
      );
    });

    test('spokenPrefixThroughAyahs returns consumed spoken through ayah 2', () {
      const String cumulative =
          'بسم الله الرحمن الرحيم الحمد لله رب العالمين الرحمن الرحيم مالك';

      expect(
        RecitationTranscriptScope.spokenPrefixThroughAyahs(
          targets: targets,
          throughTargetIndex: 2,
          sanitized: cumulative,
          normalize: normalize,
        ),
        'بسم الله الرحمن الرحىم الحمد لله رب العالمىن الرحمن الرحىم',
      );
    });
  });
}
