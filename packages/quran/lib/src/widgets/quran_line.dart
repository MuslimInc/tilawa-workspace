import 'package:flutter/material.dart';

import '../helpers/app_logger.dart';

class QuranLine extends StatelessWidget {
  const QuranLine({super.key, required this.richText});

  final RichText richText;

  @override
  Widget build(BuildContext context) {
    final renderStartTime = DateTime.now();
    // Keep the QCF glyphs at their natural proportions and
    // prevent Flutter from wrapping a single Mushaf line into a
    // second visual line.
    final result = Center(child: richText);

    final Duration renderDuration = DateTime.now().difference(renderStartTime);
    if (renderDuration.inMilliseconds > 4) {
      logger.d(
        '[PageContent] QuranLine build took ${renderDuration.inMilliseconds}ms',
      );
    }
    return result;
  }
}
