import 'dart:core';

import 'package:flutter/material.dart';

import '../../domain/entities/entities.dart';

/// A presentation widget for rendering a Quran page using Image-Based Rendering.
///
/// This widget displays 15 line images for the page.
class QuranPageWidget extends StatelessWidget {
  const QuranPageWidget({super.key, required this.page});

  final QuranPageEntity page;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFFBF3), // Cream background
      child: Column(
        children: [
          // 1. Main Content (Scaled to Fit)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 16,
                child: _Content(pageNumber: page.pageNumber),
              ),
            ),
          ),

          // 2. Page Footer
          Container(
            height: 60,
            alignment: Alignment.center,
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEE2D0).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA1887F)),
              ),
              child: Text(
                'Hizb ${page.hizb} | ${page.pageNumber}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA1887F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.pageNumber});
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(15, (index) {
        final int lineNumber = index + 1;
        final imagePath = 'assets/quranlines/p${pageNumber}_$lineNumber.png';
        return Expanded(
          child: Image.asset(
            imagePath,
            fit: BoxFit.fitWidth,
            // Handle missing lines gracefully (though they should exist)
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        );
      }),
    );
  }
}
