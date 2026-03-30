import 'package:flutter/material.dart';


class QuranLine extends StatelessWidget {
  const QuranLine({super.key, required this.richText});

  final RichText richText;

  @override
  Widget build(BuildContext context) {
    // Keep the QCF glyphs at their natural proportions and
    // prevent Flutter from wrapping a single Mushaf line into a
    // second visual line.
    return Center(child: richText);
  }
}
