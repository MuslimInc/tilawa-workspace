import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'quran_word_metadata.dart';

/// The result of a layout calculation.
@immutable
class QuranLayoutMetrics extends Equatable {
  const QuranLayoutMetrics({
    required this.fontSize,
    required this.fontHeight,
    required this.isScrollable,
    this.padding = EdgeInsets.zero,
    this.lineSpacing = 0.0,
    this.letterSpacing = 0.0,
    this.bismillahHeight = 2.5,
    this.verseHorizontalPadding = 0.0,
    this.bismillahHorizontalPadding = 0.0,
  });

  final double fontSize;
  final double fontHeight;
  final bool isScrollable;
  final EdgeInsets padding;
  final double lineSpacing;
  final double letterSpacing;
  final double bismillahHeight;
  final double verseHorizontalPadding;
  final double bismillahHorizontalPadding;

  @override
  List<Object?> get props => [
    fontSize,
    fontHeight,
    isScrollable,
    padding,
    lineSpacing,
    letterSpacing,
    bismillahHeight,
    verseHorizontalPadding,
    bismillahHorizontalPadding,
  ];
}

/// A prepared/pre-rendered page with layout, painted text, and metadata.
@immutable
class PreparedQuranPage extends Equatable {
  const PreparedQuranPage({required this.metrics, required this.blocks});

  final QuranLayoutMetrics metrics;
  final List<PreparedPageBlock> blocks;

  @override
  List<Object?> get props => [metrics, blocks];
}

/// Represents a scrollable window of prepared pages.
@immutable
class PreparedQuranPageWindow extends Equatable {
  PreparedQuranPageWindow({
    required this.centerPage,
    required this.radius,
    required Set<int> visiblePageNumbers,
    required Map<int, PreparedQuranPage> preparedPages,
  }) : visiblePageNumbers = Set<int>.unmodifiable(visiblePageNumbers),
       preparedPages = Map<int, PreparedQuranPage>.unmodifiable(preparedPages);

  final int centerPage;
  final int radius;
  final Set<int> visiblePageNumbers;
  final Map<int, PreparedQuranPage> preparedPages;

  Set<int> get pageNumbers => visiblePageNumbers;

  bool contains(int pageNumber) => visiblePageNumbers.contains(pageNumber);

  PreparedQuranPage? preparedPageFor(int pageNumber) =>
      preparedPages[pageNumber];

  @override
  List<Object?> get props => [
    centerPage,
    radius,
    visiblePageNumbers,
    preparedPages,
  ];
}

/// Base class for a prepared content block on a Quran page.
sealed class PreparedPageBlock extends Equatable {
  const PreparedPageBlock();

  @override
  List<Object?> get props => [];
}

/// A block of painted text with metadata for interaction.
class PreparedTextBlock extends PreparedPageBlock {
  const PreparedTextBlock({required this.painter, required this.metadata});

  final TextPainter painter;
  final List<QuranWordMetadata> metadata;

  @override
  List<Object?> get props => [painter, metadata];
}

/// A decorative Surah name header block.
class PreparedHeaderBlock extends PreparedPageBlock {
  const PreparedHeaderBlock({required this.surahNumber});

  final int surahNumber;

  @override
  List<Object?> get props => [surahNumber];
}

/// A Bismillah (In the name of Allah) calligraphy block.
class PreparedBismillahBlock extends PreparedPageBlock {
  const PreparedBismillahBlock();

  @override
  List<Object?> get props => [];
}

/// A blank spacer block used to preserve Mushaf vertical rhythm.
class PreparedSpacerBlock extends PreparedPageBlock {
  const PreparedSpacerBlock({required this.height});

  final double height;

  @override
  List<Object?> get props => [height];
}
