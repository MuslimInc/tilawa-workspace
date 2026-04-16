import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image_flutter/core/constants/surah_header_constants.dart';
import 'package:quran_image_flutter/domain/domain.dart';

void main() {
  group('CalibratedSurahHeaderBannerLayoutPolicy', () {
    const policy = CalibratedSurahHeaderBannerLayoutPolicy();

    test('derives line height from centralized reference dimensions', () {
      expect(
        policy.lineHeightForPageWidth(
          SurahHeaderConstants.lineHeightReferenceWidth,
        ),
        SurahHeaderConstants.lineHeightReferencePixels,
      );
    });

    test('calculates banner metrics from centralized calibration', () {
      final lineHeight = policy.lineHeightForPageWidth(1080);

      final metrics = policy.calculate(
        SurahHeaderBannerLayoutInput(
          pageWidth: 1080,
          pageHeight: 1920,
          lineHeight: lineHeight,
          inkCenterYFraction: SurahHeaderConstants.defaultInkCenterYFraction,
        ),
      );

      expect(metrics.bannerWidth, 1036);
      expect(metrics.bannerHeight, 116);
      expect(metrics.horizontalPadding, 22);
      expect(metrics.verticalOffset, closeTo(-1.044, 0.001));
    });
  });
}
