import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/domain/entities/page_state.dart';
import 'package:quran_image/page_mapping.dart';

void main() {
  test('builds one validated O(1) lookup entry per Quran page', () {
    expect(QuranPageMapping.pages, hasLength(PageState.quranPageCount));
  });

  test('returns stable metadata for representative lookup pages', () {
    expect(
      QuranPageMapping.getPageInfo(1),
      isA<PageInfo>()
          .having((info) => info.surahNumber, 'surahNumber', 1)
          .having((info) => info.juzNumber, 'juzNumber', 1)
          .having((info) => info.hizbNumber, 'hizbNumber', 1),
    );

    expect(
      QuranPageMapping.getPageInfo(553),
      isA<PageInfo>()
          .having((info) => info.surahNumber, 'surahNumber', 62)
          .having((info) => info.juzNumber, 'juzNumber', 28)
          .having((info) => info.hizbNumber, 'hizbNumber', 56),
    );

    expect(
      QuranPageMapping.getPageInfo(604),
      isA<PageInfo>()
          .having((info) => info.surahNumber, 'surahNumber', 112)
          .having((info) => info.juzNumber, 'juzNumber', 30)
          .having((info) => info.hizbNumber, 'hizbNumber', 60),
    );
  });

  test('rejects invalid page numbers', () {
    expect(() => QuranPageMapping.getPageInfo(0), throwsArgumentError);
    expect(
      () => QuranPageMapping.getPageInfo(PageState.quranPageCount + 1),
      throwsArgumentError,
    );
  });
}
