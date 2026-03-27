import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/widgets/surah_header_banner.dart';

void main() {
  group('SurahHeaderBanner sizing', () {
    // Portrait: bannerHeight = width * 0.108
    test('matches Ayah banner height on 720×1280 portrait device', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          screenSize: const Size(720, 1280),
          isLandscape: false,
        ),
        closeTo(78, 1.0),
      );
    });

    test('matches Ayah banner height on 1080×2400 portrait device', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          screenSize: const Size(1080, 2400),
          isLandscape: false,
        ),
        closeTo(117, 1.0),
      );
    });

    test('matches Ayah banner height on 1344×2992 portrait device', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          screenSize: const Size(1344, 2992),
          isLandscape: false,
        ),
        closeTo(145, 1.0),
      );
    });

    // Landscape: bannerHeight = width * 0.094
    test('matches Ayah landscape banner height on 1280×720 device', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          screenSize: const Size(1280, 720),
          isLandscape: true,
        ),
        closeTo(120, 1.0),
      );
    });

    test('matches Ayah landscape banner height on 2400×1080 device', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          screenSize: const Size(2400, 1080),
          isLandscape: true,
        ),
        closeTo(226, 1.0),
      );
    });

    test('matches Ayah landscape banner height on 2992×1344 device', () {
      expect(
        SurahHeaderBanner.computeBannerHeight(
          screenSize: const Size(2992, 1344),
          isLandscape: true,
        ),
        closeTo(281, 1.0),
      );
    });
  });
}
