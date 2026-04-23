import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../domain/models/quran_page_models.dart';

/// Renders the main text content of a Quran page.
///
/// Supports displaying a pre-rendered bitmap snapshot during scroll/swipe
/// for performance optimization, or the full interactive widget tree when idle.
class PageTextRenderer extends StatelessWidget {
  const PageTextRenderer({
    super.key,
    required this.metrics,
    required this.spacedLines,
    required this.scrollController,
    required this.snapshotBoundaryKey,
    this.snapshot,
    this.pageWidth,
    this.pageHeight,
  });

  final QuranLayoutMetrics metrics;
  final List<Widget> spacedLines;
  final ScrollController scrollController;
  final GlobalKey snapshotBoundaryKey;

  /// A pre-rendered image to display instead of the widget tree.
  final ui.Image? snapshot;

  final double? pageWidth;
  final double? pageHeight;

  @override
  Widget build(BuildContext context) {
    if (snapshot != null) {
      return RawImage(
        image: snapshot,
        fit: BoxFit.contain,
        width: pageWidth,
        height: pageHeight,
      );
    }

    final Widget pageBody = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: spacedLines,
    );

    final paddedBody = Padding(padding: metrics.padding, child: pageBody);

    final Widget result;
    if (metrics.isScrollable) {
      result = Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: scrollController,
          primary: false,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [paddedBody],
          ),
        ),
      );
    } else {
      result = paddedBody;
    }

    return RepaintBoundary(key: snapshotBoundaryKey, child: result);
  }
}
