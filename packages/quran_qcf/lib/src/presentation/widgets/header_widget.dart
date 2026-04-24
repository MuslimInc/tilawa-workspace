import 'package:flutter/material.dart';

import '../constants/quran_design_tokens.dart';
import 'surah_header_banner.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key, required this.suraNumber});
  final int suraNumber;

  @override
  Widget build(BuildContext context) {
    final Size viewportSize = MediaQuery.sizeOf(context);
    final QuranDesignTokens quranTokens = Theme.of(context).quranTokens;
    return Container(
      width: viewportSize.width,
      margin: EdgeInsets.only(top: quranTokens.headerTopPadding),
      child: SurahHeaderBanner(
        surahNumber: suraNumber,
        viewportWidth: viewportSize.width,
        viewportHeight: viewportSize.height,
        isLandscape: MediaQuery.orientationOf(context) == Orientation.landscape,
        headerTextColor: quranTokens.headerTextColor,
      ),
    );
  }
}
