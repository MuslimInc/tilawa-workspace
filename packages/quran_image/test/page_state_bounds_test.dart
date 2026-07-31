import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/domain/domain.dart';

void main() {
  group('PageState bounds', () {
    test('defaults to full Mushaf', () {
      final state = PageState.initial();
      expect(state.firstPage, 1);
      expect(state.lastPage, PageState.quranPageCount);
      expect(state.pageCount, PageState.quranPageCount);
      expect(state.pageIndex, 0);
      expect(state.isValidPage(1), isTrue);
      expect(state.isValidPage(604), isTrue);
    });

    test('pageIndex and indexToPage respect firstPage', () {
      const state = PageState(
        currentPage: 12,
        firstPage: 10,
        totalPages: 20,
        juzNumber: 1,
        hizbNumber: 1,
      );
      expect(state.pageIndex, 2);
      expect(state.pageCount, 11);
      expect(PageState.indexToPage(0, firstPage: 10), 10);
      expect(PageState.indexToPage(2, firstPage: 10), 12);
      expect(state.isValidPage(9), isFalse);
      expect(state.isValidPage(10), isTrue);
      expect(state.isValidPage(20), isTrue);
      expect(state.isValidPage(21), isFalse);
      expect(state.clampPage(5), 10);
      expect(state.clampPage(25), 20);
    });
  });
}
