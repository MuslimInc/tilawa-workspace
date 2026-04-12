import 'package:equatable/equatable.dart';

/// Represents the current page state in the Quran reader.
///
/// This entity is immutable and uses Equatable for value equality.
class PageState extends Equatable {
  /// Total number of pages in the Quran (Mushaf).
  static const int quranPageCount = 604;

  /// Current page number (1-604)
  final int currentPage;

  /// Preview page during slider drag (null when not dragging)
  final int? previewPage;

  /// Total number of pages in the Quran
  final int totalPages;

  /// Whether the page is currently being scrolled
  final bool isScrolling;

  final String juzTitle;
  final String hizbTitle;

  const PageState({
    required this.currentPage,
    required this.totalPages,
    required this.juzTitle,
    required this.hizbTitle,
    this.previewPage,
    this.isScrolling = false,
  });

  /// Creates an initial state with default values
  factory PageState.initial() {
    return const PageState(
      currentPage: 1,
      totalPages: quranPageCount,
      juzTitle: 'Juz 1',
      hizbTitle: 'Hizb 1',
      previewPage: null,
      isScrolling: false,
    );
  }

  /// Creates a copy of this state with modified fields
  /// Creates a copy of this state with modified fields.
  ///
  /// Set [clearPreviewPage] to `true` to explicitly reset
  /// [previewPage] to `null` (the `??` operator cannot do this).
  PageState copyWith({
    int? currentPage,
    int? previewPage,
    bool clearPreviewPage = false,
    int? totalPages,
    bool? isScrolling,
    String? juzTitle,
    String? hizbTitle,
  }) {
    return PageState(
      currentPage: currentPage ?? this.currentPage,
      previewPage:
          clearPreviewPage ? null : (previewPage ?? this.previewPage),
      totalPages: totalPages ?? this.totalPages,
      isScrolling: isScrolling ?? this.isScrolling,
      juzTitle: juzTitle ?? this.juzTitle,
      hizbTitle: hizbTitle ?? this.hizbTitle,
    );
  }

  /// Gets the display page (preview if available, otherwise current)
  int get displayPage => previewPage ?? currentPage;

  /// Converts page number to 0-based index for PageController
  int get pageIndex => currentPage - 1;

  /// Converts 0-based index to page number
  static int indexToPage(int index) => index + 1;

  /// Validates if a page number is within valid range
  bool isValidPage(int page) => page >= 1 && page <= totalPages;

  @override
  List<Object?> get props => [
    currentPage,
    previewPage,
    totalPages,
    isScrolling,
    juzTitle,
    hizbTitle,
  ];
}
