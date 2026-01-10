import 'package:flutter/material.dart';

import '../../../downloads/data/services/downloads_initialization_service.dart';
import '../../domain/entities/entities.dart';
import 'quran_page_widget.dart';

class QuranReaderContent extends StatelessWidget {
  const QuranReaderContent({
    super.key,
    required this.pages,
    required this.pageController,
    this.onPageChanged,
  });

  final List<QuranPageEntity> pages;
  final PageController pageController;
  final void Function(int)? onPageChanged;

  @override
  Widget build(BuildContext context) {
    logger.d('[QuranReaderContent]: ${pages.length}');
    // PageView - all pages are preloaded
    return PageView(
      controller: pageController,
      onPageChanged: (index) {
        logger.d('[QuranReaderContent]: onPageChanged: $index');
        onPageChanged?.call(index);
      },
      children: pages.map((page) => QuranPageWidget(page: page)).toList(),
    );
  }
}
