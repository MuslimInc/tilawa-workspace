import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/widgets/surah_header_banner.dart';

void main() {
  group('SurahHeaderBanner sizing', () {
    test(
      'returns Ayah-calibrated physical banner height for 1200px viewport',
      () {
        expect(SurahHeaderBanner.bannerPhysicalHeightForViewport(1200), 59);
      },
    );

    test(
      'returns Ayah-calibrated physical banner height for 1280px viewport',
      () {
        expect(SurahHeaderBanner.bannerPhysicalHeightForViewport(1280), 77);
      },
    );

    test('interpolates physical banner height between 1200px and 1280px', () {
      expect(SurahHeaderBanner.bannerPhysicalHeightForViewport(1240), 68);
    });

    test(
      'clamps physical banner height below the supported viewport range',
      () {
        expect(SurahHeaderBanner.bannerPhysicalHeightForViewport(1000), 59);
      },
    );

    test(
      'clamps physical banner height above the supported viewport range',
      () {
        expect(SurahHeaderBanner.bannerPhysicalHeightForViewport(1400), 77);
      },
    );

    test('converts 1280px physical target to logical height at 2.0 dpr', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          viewportHeight: 640,
          devicePixelRatio: 2.0,
          isPortrait: true,
          lineHeight: 50,
        ),
        38.5,
      );
    });

    test('converts 1200px physical target to logical height at 2.0 dpr', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          viewportHeight: 600,
          devicePixelRatio: 2.0,
          isPortrait: true,
          lineHeight: 50,
        ),
        29.5,
      );
    });

    test('uses line-height scaling in landscape', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          viewportHeight: 720,
          devicePixelRatio: 2.0,
          isPortrait: false,
          lineHeight: 50,
        ),
        closeTo(61, 0.001),
      );
    });
  });
}
