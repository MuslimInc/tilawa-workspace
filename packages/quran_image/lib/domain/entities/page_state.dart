import 'package:equatable/equatable.dart';

/// Represents the current page state in the Quran reader.
///
/// This entity is immutable and uses Equatable for value equality.
class PageState extends Equatable {
  /// Total number of pages in the Quran (Mushaf).
  static const int quranPageCount = 604;

  /// Current page number (absolute Mushaf page, 1-604).
  final int currentPage;

  /// Preview page during slider drag (null when not dragging)
  final int? previewPage;

  /// First allowed absolute Mushaf page in this reader session.
  final int firstPage;

  /// Last allowed absolute Mushaf page in this reader session.
  ///
  /// Named [totalPages] for historical reasons (when [firstPage] was always 1,
  /// this equalled the page count). Callers that need the count should use
  /// [pageCount].
  final int totalPages;

  /// Whether the page is currently being scrolled
  final bool isScrolling;

  final int juzNumber;
  final int hizbNumber;

  const PageState({
    required this.currentPage,
    required this.totalPages,
    required this.juzNumber,
    required this.hizbNumber,
    this.firstPage = 1,
    this.previewPage,
    this.isScrolling = false,
  });

  /// Creates an initial state with default values
  factory PageState.initial() {
    return const PageState(
      currentPage: 1,
      firstPage: 1,
      totalPages: quranPageCount,
      juzNumber: 1,
      hizbNumber: 1,
      previewPage: null,
      isScrolling: false,
    );
  }

  /// Creates a copy of this state with modified fields.
  ///
  /// Set [clearPreviewPage] to `true` to explicitly reset
  /// [previewPage] to `null` (the `??` operator cannot do this).
  PageState copyWith({
    int? currentPage,
    int? previewPage,
    bool clearPreviewPage = false,
    int? firstPage,
    int? totalPages,
    bool? isScrolling,
    int? juzNumber,
    int? hizbNumber,
  }) {
    return PageState(
      currentPage: currentPage ?? this.currentPage,
      previewPage: clearPreviewPage ? null : (previewPage ?? this.previewPage),
      firstPage: firstPage ?? this.firstPage,
      totalPages: totalPages ?? this.totalPages,
      isScrolling: isScrolling ?? this.isScrolling,
      juzNumber: juzNumber ?? this.juzNumber,
      hizbNumber: hizbNumber ?? this.hizbNumber,
    );
  }

  /// Gets the display page (preview if available, otherwise current)
  int get displayPage => previewPage ?? currentPage;

  /// Last allowed absolute page (alias of [totalPages]).
  int get lastPage => totalPages;

  /// Number of pages in the allowed range.
  int get pageCount => totalPages - firstPage + 1;

  /// Converts page number to 0-based index for PageController
  int get pageIndex => currentPage - firstPage;

  /// Converts 0-based PageView index to absolute Mushaf page number.
  static int indexToPage(int index, {int firstPage = 1}) => firstPage + index;

  /// Validates if a page number is within the allowed range
  bool isValidPage(int page) => page >= firstPage && page <= totalPages;

  /// Clamps [page] into the allowed range.
  int clampPage(int page) => page.clamp(firstPage, totalPages);

  @override
  List<Object?> get props => [
    currentPage,
    previewPage,
    firstPage,
    totalPages,
    isScrolling,
    juzNumber,
    hizbNumber,
  ];
}
