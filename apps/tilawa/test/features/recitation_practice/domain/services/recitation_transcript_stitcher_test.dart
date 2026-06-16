import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/recitation_practice/domain/services/recitation_transcript_stitcher.dart';

void main() {
  group('RecitationTranscriptStitcher', () {
    test('extends a partial with a trailing fragment', () {
      expect(
        RecitationTranscriptStitcher.extendPartial('بسم الله', 'رحيم'),
        'بسم الله رحيم',
      );
    });

    test('keeps the longer in-session partial', () {
      expect(
        RecitationTranscriptStitcher.extendPartial('بسم', 'بسم الله'),
        'بسم الله',
      );
    });

    test('stitches committed and new session segments', () {
      expect(
        RecitationTranscriptStitcher.stitch('بسم الله', 'الرحمن الرحيم'),
        'بسم الله الرحمن الرحيم',
      );
    });

    test('stitches overlapping words across sessions', () {
      expect(
        RecitationTranscriptStitcher.stitch('بسم الله الرحمن', 'الرحمن الرحيم'),
        'بسم الله الرحمن الرحيم',
      );
    });
  });
}
