import 'package:flutter/material.dart';
import 'package:quran_image_flutter/core/constants/quran_image_asset_constants.dart';
import 'package:quran_image_flutter/domain/domain.dart';
import '../atoms/atoms.dart';

/// Renders a decorative Surah header banner.
///
/// Uses the [layoutPolicy] to calculate precise render metrics (scale, offset)
/// based on the available [pageWidth], [pageHeight], and [lineHeight].
class SurahHeaderBanner extends StatelessWidget {
  const SurahHeaderBanner({
    super.key,
    required this.header,
    required this.layoutPolicy,
    required this.pageWidth,
    required this.pageHeight,
    required this.lineHeight,
    required this.bannerLocalPath,
    required this.devicePixelRatio,
  });

  final SurahHeaderData header;
  final SurahHeaderBannerLayoutPolicy layoutPolicy;
  final double pageWidth;
  final double pageHeight;
  final double lineHeight;
  final String? bannerLocalPath;
  final double devicePixelRatio;

  @override
  Widget build(BuildContext context) {
    final metrics = layoutPolicy.calculate(
      SurahHeaderBannerLayoutInput(
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        lineHeight: lineHeight,
        inkCenterYFraction: header.inkCenterYFraction,
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
      child: Center(
        child: Transform.translate(
          offset: Offset(0, metrics.verticalOffset),
          child: SizedBox(
            width: metrics.bannerWidth,
            height: metrics.bannerHeight,
            child: CachedOrRemoteImage(
              localPath: bannerLocalPath,
              remoteUrl: QuranImageAssetConstants.remoteSurahHeaderBannerUrl,
              fit: BoxFit.fill,
              gaplessPlayback: true,
              cacheWidth: (metrics.bannerWidth * devicePixelRatio).round(),
            ),
          ),
        ),
      ),
    );
  }
}
