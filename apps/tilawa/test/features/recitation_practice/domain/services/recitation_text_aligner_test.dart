import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/recitation_practice/domain/entities/word_match_status.dart';
import 'package:tilawa/features/recitation_practice/domain/services/recitation_text_aligner.dart';

void main() {
  const RecitationTextAligner aligner = RecitationTextAligner();

  group('RecitationTextAligner', () {
    test('scores perfect word-for-word alignment', () {
      final result = aligner.compare(
        targetWords: const <String>['بسم', 'الله', 'الرحمن', 'الرحيم'],
        spokenWords: const <String>['بسم', 'الله', 'الرحمن', 'الرحيم'],
        spokenText: 'بسم الله الرحمن الرحيم',
      );

      expect(result.score, 1.0);
    });

    test('skips extra spoken words without misaligning later targets', () {
      final result = aligner.compare(
        targetWords: const <String>['بسم', 'الله', 'الرحمن', 'الرحيم'],
        spokenWords: const <String>['بسم', 'و', 'الله', 'الرحمن', 'الرحيم'],
        spokenText: 'بسم و الله الرحمن الرحيم',
      );

      expect(result.score, 1.0);
    });

    test('marks a missing middle word without shifting later matches', () {
      final result = aligner.compare(
        targetWords: const <String>['بسم', 'الله', 'الرحمن', 'الرحيم'],
        spokenWords: const <String>['بسم', 'الله', 'الرحيم'],
        spokenText: 'بسم الله الرحيم',
      );

      expect(result.score, closeTo(3 / 4, 0.01));
      expect(result.words[0].status, WordMatchStatus.correct);
      expect(result.words[1].status, WordMatchStatus.correct);
      expect(result.words[2].status, WordMatchStatus.missing);
      expect(result.words[3].status, WordMatchStatus.correct);
    });

    test('accepts one-character ASR typo in medium words', () {
      final result = aligner.compare(
        targetWords: const <String>['الرحمن'],
        spokenWords: const <String>['الرحمان'],
        spokenText: 'الرحمان',
      );

      expect(result.score, 1.0);
    });

    test('accepts two-character typo in long words', () {
      final result = aligner.compare(
        targetWords: const <String>['العالمين'],
        spokenWords: const <String>['العلمين'],
        spokenText: 'العلمين',
      );

      expect(result.score, 1.0);
    });

    test('segments collapsed speech into target words', () {
      final result = aligner.compare(
        targetWords: const <String>['بسم', 'الله', 'الرحمن', 'الرحيم'],
        spokenWords: const <String>['بسماللهالرحمنالرحيم'],
        spokenText: 'بسماللهالرحمنالرحيم',
      );

      expect(result.score, 1.0);
    });

    test('returns zero score when spoken text is empty', () {
      final result = aligner.compare(
        targetWords: const <String>['بسم', 'الله'],
        spokenWords: const <String>[],
        spokenText: '',
      );

      expect(result.score, 0);
      expect(
        result.words.every(
          (word) => word.status == WordMatchStatus.missing,
        ),
        isTrue,
      );
    });

    test('does not match completely different words', () {
      final result = aligner.compare(
        targetWords: const <String>['الكافرين', 'الظالمين'],
        spokenWords: const <String>['المؤمنين', 'المصلحين'],
        spokenText: 'المؤمنين المصلحين',
      );

      expect(result.score, 0);
    });
  });
}
