import 'package:flutter/material.dart';

import 'widgets/surah_header_banner.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key, required this.suraNumber});
  final int suraNumber;

  @override
  Widget build(BuildContext context) {
    final Size viewportSize = MediaQuery.sizeOf(context);
    return Container(
      width: viewportSize.width,
      margin: const EdgeInsets.only(top: 12),
      child: SurahHeaderBanner(
        surahNumber: suraNumber,
        viewportWidth: viewportSize.width,
        viewportHeight: viewportSize.height,
        isLandscape: MediaQuery.orientationOf(context) == Orientation.landscape,
        headerTextColor: Colors.black,
      ),
    );
  }
}
