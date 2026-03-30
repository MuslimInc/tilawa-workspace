import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:quran/src/page_content.dart';

import '../../../quran_reader/presentation/theme/quran_reader_theme.dart';

final ValueNotifier<bool> _hiddenReaderPageOverlays = ValueNotifier<bool>(
  false,
);

/// Dedicated capture/preview surface for a single Mushaf page.
///
/// This mirrors the Quran reader page content without relying on the live
/// `PageView` route underneath the share composer.
class ReaderPageContentRenderer extends StatelessWidget {
  const ReaderPageContentRenderer({
    super.key,
    required this.pageNumber,
    this.uiTextDirection = TextDirection.ltr,
  });

  final int pageNumber;
  final TextDirection uiTextDirection;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final QuranReaderTheme readerTheme = QuranReaderTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: readerTheme.pageBackground),
      child: MediaQuery(
        data: mediaQuery.copyWith(
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.zero,
          viewInsets: EdgeInsets.zero,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: PageContent(
            pageNumber: pageNumber,
            textColor: readerTheme.textColor,
            pageBackgroundColor: readerTheme.pageBackground,
            headerImageFilter: readerTheme.headerImageFilter,
            headerTextColor: readerTheme.headerTextColor,
            headerFontSizeMultiplier: 0.57,
            uiTextDirection: uiTextDirection,
            showOverlaysListenable: _hiddenReaderPageOverlays,
          ),
        ),
      ),
    );
  }
}
