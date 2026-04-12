import 'dart:async';

import '../../domain/domain.dart';
import '../../page_mapping.dart';

/// In-memory implementation of [PageRepository].
///
/// This implementation stores page state in memory and provides
/// reactive updates via a StreamController. For production, this
/// should be replaced with a persistent storage implementation
/// using SharedPreferences or similar.
class InMemoryPageRepository implements PageRepository {
  PageState _currentState = PageState.initial();
  final _pageController = StreamController<PageState>.broadcast();

  @override
  Future<PageState> getCurrentPage() async {
    return _currentState;
  }

  @override
  Future<void> savePageState(PageState state) async {
    _currentState = state;
    _pageController.add(state);
  }

  @override
  Future<PageState> navigateToPage(int pageNumber) async {
    if (!_currentState.isValidPage(pageNumber)) {
      throw ArgumentError('Invalid page number: $pageNumber');
    }

    final info = QuranPageMapping.getPageInfo(pageNumber);
    final newState = _currentState.copyWith(
      currentPage: pageNumber,
      juzTitle: info.juzTitle,
      hizbTitle: info.hizbTitle,
    );
    await savePageState(newState);
    return newState;
  }

  @override
  Future<PageState> nextPage() async {
    final next = _currentState.currentPage + 1;
    if (!_currentState.isValidPage(next)) {
      return _currentState; // Already at last page
    }
    return navigateToPage(next);
  }

  @override
  Future<PageState> previousPage() async {
    final prev = _currentState.currentPage - 1;
    if (!_currentState.isValidPage(prev)) {
      return _currentState; // Already at first page
    }
    return navigateToPage(prev);
  }

  @override
  Stream<PageState> watchPageState() {
    return _pageController.stream;
  }

  /// Disposes the repository resources
  void dispose() {
    _pageController.close();
  }
}
