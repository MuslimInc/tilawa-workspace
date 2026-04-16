import 'package:equatable/equatable.dart';

/// Represents the data required to position a Surah header on a specific page.
class SurahHeaderData extends Equatable {
  /// The Quran page number where this header is displayed.
  final int pageNumber;

  /// The 0-based image-file line index (0-14) representing the slot for this header.
  final int lineIndex;

  /// The vertical center fraction required to align the banner with the line's ink.
  final double inkCenterYFraction;

  /// Creates a [SurahHeaderData] representation for a page.
  const SurahHeaderData({
    required this.pageNumber,
    required this.lineIndex,
    required this.inkCenterYFraction,
  });

  @override
  List<Object?> get props => [pageNumber, lineIndex, inkCenterYFraction];
}
