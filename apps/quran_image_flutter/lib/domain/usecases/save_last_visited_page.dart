import '../entities/page_state.dart';
import '../repositories/last_visited_page_repository.dart';

/// Use case for saving the last visited (or jumped-to) page.
///
/// This follows the Single Responsibility Principle (SRP) by encapsulating
/// the logic for persisting the last visited page into a dedicated use case.
/// It also follows the Dependency Inversion Principle (DIP) by depending on
/// the abstract repository interface rather than concrete implementations.
class SaveLastVisitedPageUseCase {
  final LastVisitedPageRepository _repository;

  const SaveLastVisitedPageUseCase(this._repository);

  /// Executes the use case to save the last visited page.
  ///
  /// [pageNumber] must be a valid Quran page number (1-604).
  /// Throws [ArgumentError] if the page number is invalid.
  Future<void> execute(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > PageState.quranPageCount) {
      throw ArgumentError(
        'Invalid page number: $pageNumber. '
        'Must be between 1 and ${PageState.quranPageCount}.',
      );
    }
    await _repository.saveLastVisitedPage(pageNumber);
  }
}
