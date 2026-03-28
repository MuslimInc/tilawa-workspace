import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/widgets/surah_header_banner.dart';

void main() {
  group('SurahHeaderBanner sizing', () {
    test('matches portrait banner height on 720x1280 device', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          viewportWidth: 720,
          viewportHeight: 1280,
          isLandscape: false,
        ),
        closeTo(77, 0.8),
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
}
