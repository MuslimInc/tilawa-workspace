import '../entities/page_state.dart';

/// Repository interface for page navigation operations.
///
/// This abstract class defines the contract for page-related data operations,
/// following the Repository Pattern from Clean Architecture.
abstract class PageRepository {
  /// Gets the current page state
  Future<PageState> getCurrentPage();

  /// Saves the current page state
  Future<void> savePageState(PageState state);

  /// Navigates to a specific page
  Future<PageState> navigateToPage(int pageNumber);

  /// Navigates to the next page
  Future<PageState> nextPage();

  /// Navigates to the previous page
  Future<PageState> previousPage();

  /// Stream of page state changes for reactive UI updates
  Stream<PageState> watchPageState();
}
