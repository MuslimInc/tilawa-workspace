import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/constants/quran_constants.dart';
import 'package:quran_qcf/src/constants/surah_header_banner_constants.dart';
import 'package:quran_qcf/src/layout/surah_header_banner_layout.dart';
import 'package:quran_qcf/src/widgets/surah_header_banner.dart';
import 'package:quran_qcf/src/widgets/surah_header_glyph_provider.dart';

void main() {
  group('SurahHeaderBanner sizing', () {
    test('matches portrait banner height on 720x1280 device', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          viewportWidth: 720,
          viewportHeight: 1280,
          isLandscape: false,
        ),
        closeTo(78, 0.6),
      );
    });

    test('matches portrait banner height on 1080x2400 device', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          viewportWidth: 1080,
          viewportHeight: 2400,
          isLandscape: false,
        ),
        closeTo(117, 0.6),
      );
    });

    test('matches portrait banner height on 1344x2992 device', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          viewportWidth: 1344,
          viewportHeight: 2992,
          isLandscape: false,
        ),
        closeTo(145, 0.8),
      );
    });

    test('matches portrait horizontal padding on 720x1280 device', () {
      expect(
        SurahHeaderBanner.computeHorizontalPadding(
          viewportWidth: 720,
          viewportHeight: 1280,
          isLandscape: false,
        ),
        closeTo(14, 1.0),
      );
    });

    test('matches portrait horizontal padding on 1080x2400 device', () {
      expect(
        SurahHeaderBanner.computeHorizontalPadding(
          viewportWidth: 1080,
          viewportHeight: 2400,
          isLandscape: false,
        ),
        closeTo(21, 1.0),
      );
    });

    test('matches portrait horizontal padding on 1344x2992 device', () {
      expect(
        SurahHeaderBanner.computeHorizontalPadding(
          viewportWidth: 1344,
          viewportHeight: 2992,
          isLandscape: false,
        ),
        closeTo(27, 1.0),
      );
    });

    test('matches landscape banner height on 1280x720 device', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          viewportWidth: 1280,
          viewportHeight: 720,
          isLandscape: true,
        ),
        closeTo(134, 0.6),
      );
    });

    test('matches landscape banner height on 2400x1080 device', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          viewportWidth: 2400,
          viewportHeight: 1080,
          isLandscape: true,
        ),
        closeTo(224, 1.0),
      );
    });

    test('matches landscape banner height on 2992x1344 device', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          viewportWidth: 2992,
          viewportHeight: 1344,
          isLandscape: true,
        ),
        closeTo(282, 1.0),
      );
    });

    test('matches landscape horizontal padding on 1280x720 device', () {
      expect(
        SurahHeaderBanner.computeHorizontalPadding(
          viewportWidth: 1280,
          viewportHeight: 720,
          isLandscape: true,
        ),
        closeTo(44, 2.0),
      );
    });

    test('matches landscape horizontal padding on 2400x1080 device', () {
      expect(
        SurahHeaderBanner.computeHorizontalPadding(
          viewportWidth: 2400,
          viewportHeight: 1080,
          isLandscape: true,
        ),
        closeTo(204, 8.0),
      );
    });

    test('matches landscape horizontal padding on 2992x1344 device', () {
      expect(
        SurahHeaderBanner.computeHorizontalPadding(
          viewportWidth: 2992,
          viewportHeight: 1344,
          isLandscape: true,
        ),
        closeTo(242, 8.0),
      );
    });
  });

  group('SurahHeaderBanner centralized collaborators', () {
    test('calculates all banner metrics through the layout policy', () {
      final SurahHeaderBannerLayoutMetrics metrics =
          SurahHeaderBanner.calculateLayout(
            viewportWidth: 720,
            viewportHeight: 1280,
            isLandscape: false,
          );

      expect(metrics.width, closeTo(691, 1.0));
      expect(metrics.height, closeTo(78, 0.6));
      expect(metrics.horizontalPadding, closeTo(14, 1.0));
      expect(
        metrics.fontSize,
        closeTo(
          metrics.height * SurahHeaderBannerConstants.defaultFontSizeMultiplier,
          0.01,
        ),
      );
      expect(
        metrics.titleVerticalOffset,
        closeTo(
          metrics.height * SurahHeaderBannerConstants.titleVerticalOffsetRatio,
          0.01,
        ),
      );
    });

    test('uses O(1) indexed QCF glyph lookup for boundary surahs', () {
      const SurahHeaderGlyphProvider glyphProvider =
          QcfSurahHeaderGlyphProvider();

      expect(
        glyphProvider.glyphForSurah(QuranConstants.minSurahNumber).runes.single,
        SurahHeaderBannerConstants.glyphBaseCodePoint,
      );
      expect(
        glyphProvider.glyphForSurah(QuranConstants.maxSurahNumber).runes.single,
        SurahHeaderBannerConstants.glyphBaseCodePoint +
            QuranConstants.totalSurahCount -
            1,
      );
    });

    test('rejects invalid surah numbers before glyph lookup', () {
      const SurahHeaderGlyphProvider glyphProvider =
          QcfSurahHeaderGlyphProvider();

      expect(
        () => glyphProvider.glyphForSurah(QuranConstants.minSurahNumber - 1),
        throwsRangeError,
      );
      expect(
        () => glyphProvider.glyphForSurah(QuranConstants.maxSurahNumber + 1),
        throwsRangeError,
      );
    });
  });
}
