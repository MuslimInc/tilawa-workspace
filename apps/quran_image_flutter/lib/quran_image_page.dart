import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quran_image_flutter/core/di/dependency_injection.dart';
import 'package:quran_image_flutter/domain/domain.dart';
import 'package:quran_image_flutter/verse_marker.dart';

/// Renders a full Quran page using the same layout algorithm as the Ayah app.
///
/// The Ayah app's `QuranLineLayout` (Kotlin) places each line at:
///   y = floor((pageHeight - lineHeight) / 14 * lineIndex)
/// where:
///   lineHeight = pageWidth * 174 / 1080
///   lineIndex  = 0-based (0–14)
///
/// Each line image is the same 1440×232 aspect ratio → ratio = 232/1440 ≈ 0.1611.
class QuranImagePage extends StatelessWidget {
  static const int _lineCount = 15;

  /// A mapping of page numbers to the 0-based line indices where surah header
  /// banners should be rendered. Calculated via alpha-span heuristic.
  static const Map<int, List<int>> _surahHeaderMapping = {
    1: [3],
    2: [3],
    50: [0],
    77: [0],
    106: [5],
    128: [0],
    151: [0],
    177: [0],
    187: [0],
    208: [0],
    221: [6],
    235: [8],
    249: [0],
    255: [2],
    262: [0],
    267: [6],
    282: [0],
    293: [9],
    305: [0],
    312: [4],
    322: [0],
    332: [0],
    342: [0],
    350: [0],
    359: [10],
    367: [0],
    377: [0],
    385: [7],
    396: [7],
    404: [9],
    411: [0],
    415: [0],
    418: [0],
    428: [0],
    434: [7],
    440: [3],
    446: [0],
    453: [0],
    458: [3],
    467: [2],
    477: [0],
    483: [0],
    489: [4],
    496: [0],
    499: [0],
    502: [6],
    507: [0],
    511: [0],
    515: [6],
    518: [0],
    520: [11],
    523: [7],
    526: [0],
    528: [9],
    531: [4],
    534: [6],
    537: [10],
    542: [0],
    545: [6],
    549: [0],
    551: [6],
    553: [0],
    554: [6],
    556: [0],
    558: [0],
    560: [0],
    562: [0],
    564: [5],
    566: [9],
    568: [8],
    570: [4],
    572: [0],
    574: [0],
    575: [7],
    577: [5],
    578: [9],
    580: [6],
    582: [0],
    583: [7],
    585: [0],
    586: [1],
    587: [0, 11],
    589: [2],
    590: [1],
    591: [0, 9],
    592: [4],
    593: [2],
    594: [5],
    595: [1, 10],
    596: [5, 12],
    597: [2, 8],
    598: [3, 8],
    599: [5, 11],
    600: [3, 10],
    601: [0, 4, 10],
    602: [0, 5, 11],
    603: [0, 5, 10],
    604: [0, 4, 9],
  };

  final int pageNumber;

  const QuranImagePage({super.key, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final markers = sl<VerseMarkerRepository>().getMarkersForPage(pageNumber);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double pageWidth = constraints.maxWidth;
        final double pageHeight = constraints.maxHeight;
        final bool isLandscape = pageWidth > pageHeight;

        // Always use the Ayah app formula: lineHeight derives from width.
        // In landscape the total content height exceeds the viewport,
        // so we wrap in a scroll view.
        final double lineHeight = pageWidth * 174 / 1080;

        // Calculate the optimal physical width to force the C++ native decoder
        // to dramatically scale down the 1440px images BEFORE hitting the GPU VRAM bus.
        final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        final int cacheWidth = (pageWidth * devicePixelRatio).round();

        // In landscape, content overflows — use total content height for layout.
        final double layoutHeight = isLandscape
            ? lineHeight *
                  _lineCount // no gaps, lines fill tightly
            : pageHeight;

        const double lastLineIndex = _lineCount - 1;
        final List<double> yOffsets = List.generate(_lineCount, (i) {
          return ((layoutHeight - lineHeight) / lastLineIndex * i);
        });

        final headerIndices = _surahHeaderMapping[pageNumber] ?? [];

        final content = SizedBox(
          width: pageWidth,
          height: layoutHeight,
          child: Stack(
            children: [
              // Surah header banner behind the surah name lines.
              for (final headerIndex in headerIndices)
                Positioned(
                  left: 0,
                  right: 0,
                  top: yOffsets[headerIndex],
                  height: lineHeight,
                  child: _SurahHeaderBanner(
                    pageNumber: pageNumber,
                    lineIndex: headerIndex,
                    lineHeight: lineHeight,
                    pageWidth: pageWidth,
                    pageHeight: pageHeight,
                  ),
                ),

              for (var i = 0; i < _lineCount; i++)
                Positioned(
                  left: 0,
                  right: 0,
                  top: yOffsets[i],
                  child: Image.asset(
                    'assets/quran_images/$pageNumber/${i + 1}.png',
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                    cacheWidth: cacheWidth,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),

              for (final marker in markers)
                _AyahMarkerWidget(
                  marker: marker,
                  pageWidth: pageWidth,
                  pageHeight: layoutHeight,
                  lineHeight: lineHeight,
                  yOffsets: yOffsets,
                ),
            ],
          ),
        );

        // In landscape, content is taller than the viewport — scroll vertically.
        if (isLandscape) {
          return SingleChildScrollView(child: content);
        }
        return content;
      },
    );
  }
}

/// Renders the decorative Surah header banner image.
///
/// Banner width is computed using a linear regression model calibrated
/// against Figma measurements from the Ayah app across multiple devices.
/// Height follows the intrinsic aspect ratio of the banner image asset.
class _SurahHeaderBanner extends StatelessWidget {
  const _SurahHeaderBanner({
    required this.pageNumber,
    required this.lineIndex,
    required this.lineHeight,
    required this.pageWidth,
    required this.pageHeight,
  });

  final int pageNumber;
  final int lineIndex;
  final double lineHeight;
  final double pageWidth;
  final double pageHeight;

  static const double _bannerHeightToWidthRatio = 0.11228293967474158;
  static const double _portraitWidthRatioBase = 0.97354259;
  static const double _portraitWidthRatioAspectSlope = -0.015786;
  static const double _portraitWidthRatioViewportSlope = -0.0000049331266667;
  static const double _targetInkCenterYFraction = 0.509;

  // Header line assets do not all place the surah-name calligraphy at the
  // same vertical center. Ayah's banner positioning compensates for that, so
  // we precompute the alpha-center for each header line and nudge the banner
  // inside the line slot to keep the calligraphy centered in the window.
  static const Map<int, Map<int, double>> _headerInkCenterYFractions = {
    1: {3: 0.5000, 11: 0.5108},
    2: {3: 0.5022, 11: 0.5108},
    50: {0: 0.4526},
    77: {0: 0.4806},
    106: {5: 0.5302},
    128: {0: 0.4504},
    151: {0: 0.4461},
    177: {0: 0.4612},
    187: {0: 0.4720},
    208: {0: 0.4569},
    221: {6: 0.4698},
    235: {8: 0.5560},
    249: {0: 0.4720},
    255: {2: 0.4914},
    262: {0: 0.4634},
    267: {6: 0.5043},
    282: {0: 0.4698},
    293: {9: 0.6099},
    305: {0: 0.4569},
    312: {4: 0.4957},
    322: {0: 0.4591},
    332: {0: 0.4655},
    342: {0: 0.4655},
    350: {0: 0.4634},
    359: {10: 0.5711},
    367: {0: 0.4634},
    377: {0: 0.4655},
    385: {7: 0.5539},
    396: {7: 0.5237},
    404: {9: 0.6250},
    411: {0: 0.4504},
    415: {0: 0.4591},
    418: {0: 0.4612},
    428: {0: 0.4741},
    434: {7: 0.5841},
    440: {3: 0.4741},
    446: {0: 0.4677},
    453: {0: 0.4634},
    458: {3: 0.5280},
    467: {2: 0.5453},
    477: {0: 0.4634},
    483: {0: 0.4612},
    489: {4: 0.5948},
    496: {0: 0.4677},
    499: {0: 0.4612},
    502: {6: 0.5323},
    507: {0: 0.4741},
    511: {0: 0.4763},
    515: {6: 0.5841},
    518: {0: 0.4655},
    520: {11: 0.5927},
    523: {7: 0.5129},
    526: {0: 0.4677},
    528: {9: 0.5043},
    531: {4: 0.5690},
    534: {6: 0.5151},
    537: {10: 0.5991},
    542: {0: 0.4612},
    545: {6: 0.5172},
    549: {0: 0.4655},
    551: {6: 0.5474},
    553: {0: 0.4655},
    554: {6: 0.5517},
    556: {0: 0.4720},
    558: {0: 0.4634},
    560: {0: 0.4698},
    562: {0: 0.4547},
    564: {5: 0.5948},
    566: {9: 0.5517},
    568: {8: 0.5991},
    570: {4: 0.5237},
    572: {0: 0.4698},
    574: {0: 0.4634},
    575: {7: 0.5302},
    577: {5: 0.4634},
    578: {9: 0.5302},
    580: {6: 0.5237},
    582: {0: 0.4763},
    583: {7: 0.5582},
    585: {0: 0.4612},
    586: {1: 0.5259},
    587: {0: 0.4698, 11: 0.5690},
    589: {2: 0.5172},
    590: {1: 0.5366},
    591: {0: 0.4655, 9: 0.5474},
    592: {4: 0.4978},
    593: {2: 0.4978},
    594: {5: 0.5560},
    595: {1: 0.5216, 10: 0.5690},
    596: {5: 0.5000, 12: 0.5151},
    597: {2: 0.5496, 8: 0.5366},
    598: {3: 0.5302, 8: 0.6142},
    599: {5: 0.5409, 11: 0.5733},
    600: {3: 0.5043, 10: 0.4935},
    601: {0: 0.4634, 4: 0.5280, 10: 0.6013},
    602: {0: 0.4634, 5: 0.5884, 11: 0.5690},
    603: {0: 0.4461, 5: 0.5431, 10: 0.5690},
    604: {0: 0.4483, 4: 0.5237, 9: 0.5862},
  };

  @override
  Widget build(BuildContext context) {
    final double shortSide = math.min(pageWidth, pageHeight);
    final double longSide = math.max(pageWidth, pageHeight);
    final double aspectRatio = longSide > 0 ? shortSide / longSide : 0;

    // Line images always fill pageWidth in both orientations,
    // so the banner always uses the portrait regression model.
    final double widthRatio =
        (_portraitWidthRatioBase +
                (_portraitWidthRatioAspectSlope * aspectRatio) +
                (_portraitWidthRatioViewportSlope * pageWidth))
            .clamp(0.0, 1.0);

    final double bannerWidth = (pageWidth * widthRatio).roundToDouble();
    final double bannerHeight = (bannerWidth * _bannerHeightToWidthRatio)
        .roundToDouble();
    final double horizontalPadding = (pageWidth - bannerWidth) / 2;
    final double centeredTop = (lineHeight - bannerHeight) / 2;
    final double headerInkCenterYFraction =
        _headerInkCenterYFractions[pageNumber]?[lineIndex] ?? 0.5;
    final double desiredTop =
        (lineHeight * headerInkCenterYFraction) -
        (bannerHeight * _targetInkCenterYFraction);
    final double verticalOffset = desiredTop - centeredTop;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Center(
        child: Transform.translate(
          offset: Offset(0, verticalOffset),
          child: SizedBox(
            height: bannerHeight,
            width: bannerWidth,
            child: Image.asset(
              'assets/images/sura_header_banner.png',
              gaplessPlayback: true,
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
    );
  }
}

class _AyahMarkerWidget extends StatelessWidget {
  final VerseMarkerData marker;
  final double pageWidth;
  final double pageHeight;
  final double lineHeight;
  final List<double> yOffsets;

  const _AyahMarkerWidget({
    required this.marker,
    required this.pageWidth,
    required this.pageHeight,
    required this.lineHeight,
    required this.yOffsets,
  });

  @override
  Widget build(BuildContext context) {
    // Precise: Based on Ayah app measurement of 37x47 px on a 720 px-wide screen.
    final double markerW = pageWidth * 0.05138889;
    final double markerH = pageWidth * 0.06527778;

    final double xOffset = (marker.centerX * pageWidth - markerW / 2).clamp(
      0.0,
      pageWidth - markerW,
    );

    // marker.line is the 0-based image-file index (0–14).
    // yCenter = top of that line's slot + half a line height (vertical centre).
    final int idx = marker.line.clamp(0, 14);
    final double yCenter = yOffsets[idx] + lineHeight / 2;

    return Positioned(
      left: xOffset,
      top: yCenter - markerH / 2,
      child: VerseMarker(
        verseNumber: marker.ayah,
        width: markerW,
        height: markerH,
      ),
    );
  }
}
