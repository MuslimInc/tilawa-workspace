import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/domain/reader_slider_jump_policy.dart';

/// Scenario coverage for slider jump performance fix (snapshot only when needed).
///
/// Targets ~90% of meaningful **delta** classes: boundary, typical medium/long
/// jumps, and extremes. Pair with widget tests for [PageSlider] and the reader
/// thumb-drag regression.
void main() {
  group('quranReaderShouldUseJumpTransitionSnapshot', () {
    test('false for delta below threshold (fast path)', () {
      expect(quranReaderShouldUseJumpTransitionSnapshot(0), isFalse);
      expect(quranReaderShouldUseJumpTransitionSnapshot(1), isFalse);
      expect(quranReaderShouldUseJumpTransitionSnapshot(3), isFalse);
      expect(quranReaderShouldUseJumpTransitionSnapshot(10), isFalse);
      expect(quranReaderShouldUseJumpTransitionSnapshot(24), isFalse);
      expect(quranReaderShouldUseJumpTransitionSnapshot(35), isFalse);
    });

    test('true at threshold and above (snapshot-eligible path)', () {
      expect(quranReaderShouldUseJumpTransitionSnapshot(36), isTrue);
      expect(quranReaderShouldUseJumpTransitionSnapshot(37), isTrue);
      expect(quranReaderShouldUseJumpTransitionSnapshot(79), isTrue);
      expect(quranReaderShouldUseJumpTransitionSnapshot(100), isTrue);
      expect(quranReaderShouldUseJumpTransitionSnapshot(603), isTrue);
    });
  });

  group('quranReaderJumpSnapshotMinPageDelta', () {
    test('matches reader long-jump branch expectations', () {
      expect(quranReaderJumpSnapshotMinPageDelta, 36);
      expect(
        quranReaderShouldUseJumpTransitionSnapshot(
          quranReaderJumpSnapshotMinPageDelta,
        ),
        isTrue,
      );
      expect(
        quranReaderShouldUseJumpTransitionSnapshot(
          quranReaderJumpSnapshotMinPageDelta - 1,
        ),
        isFalse,
      );
    });
  });
}
