import '../repositories/last_visited_page_repository.dart';
import '../entities/page_state.dart';

/// Use case for retrieving the last visited page.
///
/// This follows the Single Responsibility Principle (SRP) by encapsulating
/// the logic for retrieving the last visited page into a dedicated use case.
/// It also follows the Dependency Inversion Principle (DIP) by depending on
/// the abstract repository interface rather than concrete implementations.
class GetLastVisitedPageUseCase {
  final LastVisitedPageRepository _repository;

  const GetLastVisitedPageUseCase(this._repository);

  /// Executes the use case to get the last visited page.
  ///
  /// Returns the saved page number, or null if no page has been saved.
  Future<int?> execute() async {
    return await _repository.getLastVisitedPage();
  }

  /// Executes the use case and returns a valid page number.
  ///
  /// Returns the saved page number if available and valid,
  /// otherwise returns the [defaultPage].
  Future<int> executeOrDefault(int defaultPage) async {
    final savedPage = await execute();
    if (savedPage != null &&
        savedPage >= 1 &&
        savedPage <= PageState.quranPageCount) {
      return savedPage;
    }
    return defaultPage;
  }
}
