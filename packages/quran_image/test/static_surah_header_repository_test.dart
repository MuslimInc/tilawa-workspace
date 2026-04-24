import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/core/constants/surah_header_constants.dart';
import 'package:quran_image/data/data.dart';

void main() {
  group('StaticSurahHeaderRepository', () {
    const repository = StaticSurahHeaderRepository();

    test('returns an empty constant list for pages without headers', () {
      expect(repository.getHeadersForPage(3), isEmpty);
    });

    test('returns only actual header slots for early pages', () {
      final pageOneHeaders = repository.getHeadersForPage(1);
      final pageTwoHeaders = repository.getHeadersForPage(2);

      expect(pageOneHeaders, hasLength(1));
      expect(pageOneHeaders.single.lineIndex, 3);
      expect(
        pageOneHeaders.single.inkCenterYFraction,
        SurahHeaderConstants.defaultInkCenterYFraction,
      );

      expect(pageTwoHeaders, hasLength(1));
      expect(pageTwoHeaders.single.lineIndex, 3);
      expect(pageTwoHeaders.single.inkCenterYFraction, 0.5022);
    });

    test('keeps multi-header pages in page-order O(1) buckets', () {
      final headers = repository.getHeadersForPage(604);

      expect(headers.map((header) => header.lineIndex), [0, 4, 9]);
      expect(headers.map((header) => header.inkCenterYFraction), [
        0.4483,
        0.5237,
        0.5862,
      ]);
    });
  });
}
