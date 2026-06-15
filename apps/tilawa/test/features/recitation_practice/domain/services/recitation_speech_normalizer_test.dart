import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/features/recitation_practice/domain/services/recitation_speech_normalizer.dart';

void main() {
  late RecitationSpeechNormalizer normalizer;

  setUp(() {
    normalizer = const RecitationSpeechNormalizer(
      TextNormalizationServiceImpl(),
    );
  });

  group('RecitationSpeechNormalizer', () {
    test('normalizes hamza and alif variants to plain ASR form', () {
      final String normalized = normalizer.normalize('إِيَّاكَ نَعْبُدُ');
      final String plainAsr = normalizer.normalize('اياك نعبد');

      expect(normalized, plainAsr);
    });

    test('strips Arabic punctuation from speech', () {
      final String withPunctuation = normalizer.normalize(
        'الحمد لله، رب العالمين؟',
      );
      final String plain = normalizer.normalize('الحمد لله رب العالمين');

      expect(withPunctuation, plain);
    });

    test('replaces Allah ligature', () {
      expect(
        normalizer.normalize('بسم \uFDF2'),
        'بسم الله',
      );
    });

    test('sanitize keeps Arabic and drops Latin noise', () {
      final String sanitized = normalizer.sanitizeSpokenTranscript(
        'بسم الله الرحمن الرحيم man you are a man',
      );
      final String plain = normalizer.normalize('بسم الله الرحمن الرحيم');

      expect(sanitized, plain);
    });

    test('sanitize returns empty for English-only transcript', () {
      expect(
        normalizer.sanitizeSpokenTranscript("man you're a man"),
        '',
      );
    });

    test('sanitize normalizes wasla alef', () {
      expect(
        normalizer.sanitizeSpokenTranscript('ٱلرَّحْمَٰنِ'),
        'الرحمن',
      );
    });
  });
}
