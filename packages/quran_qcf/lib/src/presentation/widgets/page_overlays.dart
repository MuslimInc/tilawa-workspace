import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/models/page_meta_info.dart';
import '../../domain/models/quran_page_models.dart';
import '../../helpers/convert_to_arabic_number.dart';
import 'page_metadata_strip.dart';
import 'page_number_badge.dart';

/// Renders the UI overlays for a Quran page (metadata strip and page number).
///
/// Uses [TilawaDesignTokens] for consistent spacing and typography.
class PageOverlays extends StatelessWidget {
  const PageOverlays({
    super.key,
    required this.pageNumber,
    required this.showOverlaysListenable,
    required this.uiTextDirection,
    required this.metrics,
    required this.pageMeta,
    required this.metaTextColor,
    required this.badgeColor,
    required this.borderColor,
    required this.textColor,
    this.onShowIndex,
  });

  final int pageNumber;
  final ValueListenable<bool>? showOverlaysListenable;
  final TextDirection uiTextDirection;
  final QuranLayoutMetrics metrics;
  final PageMetaInfo? pageMeta;
  final Color metaTextColor;
  final Color badgeColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback? onShowIndex;

  @override
  Widget build(BuildContext context) {
    if (showOverlaysListenable == null) return const SizedBox.shrink();

    final String pageNumberLabel = uiTextDirection == TextDirection.rtl
        ? convertToArabicNumber(pageNumber.toString())
        : pageNumber.toString();

    return Stack(
      children: [
        Positioned(
          top: metrics.padding.top,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: showOverlaysListenable!,
            builder: (context, show, child) {
              return Visibility(visible: show, child: child!);
            },
            child: _MetadataStrip(
              surahNames: pageMeta?.surahNames.join(', ') ?? '',
              juzLabel: pageMeta?.juzLabel ?? '',
              uiTextDirection: uiTextDirection,
              textColor: metaTextColor,
              onShowIndex: onShowIndex,
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 6, // Standard horizontal offset for page badge
          child: ValueListenableBuilder<bool>(
            valueListenable: showOverlaysListenable!,
            builder: (context, show, child) {
              return Visibility(visible: show, child: child!);
            },
            child: PageNumberBadge(
              label: pageNumberLabel,
              backgroundColor: badgeColor,
              borderColor: borderColor,
              textColor: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetadataStrip extends StatelessWidget {
  const _MetadataStrip({
    required this.surahNames,
    required this.juzLabel,
    required this.uiTextDirection,
    required this.textColor,
    this.onShowIndex,
  });

  final String surahNames;
  final String juzLabel;
  final TextDirection uiTextDirection;
  final Color textColor;
  final VoidCallback? onShowIndex;

  @override
  Widget build(BuildContext context) {
    if (surahNames.isEmpty) return const SizedBox.shrink();

    Widget strip = PageMetadataStrip(
      surahNames: surahNames,
      juzLabel: juzLabel,
      uiTextDirection: uiTextDirection,
      textColor: textColor,
    );

    if (onShowIndex != null) {
      strip = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onShowIndex,
        child: strip,
      );
    }

    return strip;
  }
}
