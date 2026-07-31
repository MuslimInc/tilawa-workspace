import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/data/repositories/in_memory_page_repository.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_event.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_state.dart';

void main() {
  group('NavigationBloc page bounds', () {
    test('initializes with page bounds and clamps initial page', () async {
      final bloc = NavigationBloc(
        pageRepository: InMemoryPageRepository(),
        visibilityRepository: _TestNavigationVisibilityRepository(),
        saveLastVisitedPageUseCase: SaveLastVisitedPageUseCase(
          _TestLastVisitedPageRepository(),
        ),
        getLastVisitedPageUseCase: GetLastVisitedPageUseCase(
          _TestLastVisitedPageRepository(initialPage: 100),
        ),
      );
      addTearDown(bloc.close);

      bloc.add(
        const NavigationInitialized(
          initialPage: 100,
          firstPage: 1,
          lastPage: 5,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final state = bloc.state;
      expect(state, isA<NavigationLoaded>());
      final loaded = state as NavigationLoaded;
      expect(loaded.pageState.currentPage, 5);
      expect(loaded.pageState.firstPage, 1);
      expect(loaded.pageState.totalPages, 5);
      expect(loaded.pageState.pageCount, 5);
    });

    test('PageChanged clamps into session bounds', () async {
      final bloc = NavigationBloc(
        pageRepository: InMemoryPageRepository(),
        visibilityRepository: _TestNavigationVisibilityRepository(),
        saveLastVisitedPageUseCase: SaveLastVisitedPageUseCase(
          _TestLastVisitedPageRepository(),
        ),
        getLastVisitedPageUseCase: GetLastVisitedPageUseCase(
          _TestLastVisitedPageRepository(initialPage: 1),
        ),
      );
      addTearDown(bloc.close);

      bloc.add(
        const NavigationInitialized(
          initialPage: 1,
          firstPage: 10,
          lastPage: 20,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      bloc.add(const PageChanged(604));
      await Future<void>.delayed(Duration.zero);

      final loaded = bloc.state as NavigationLoaded;
      expect(loaded.pageState.currentPage, 20);
    });
  });
}

class _TestNavigationVisibilityRepository
    implements NavigationVisibilityRepository {
  NavigationVisibility _currentVisibility = NavigationVisibility.initial();

  @override
  Future<NavigationVisibility> endInteraction() =>
      SynchronousFuture<NavigationVisibility>(_currentVisibility);

  @override
  Future<NavigationVisibility> getVisibility() =>
      SynchronousFuture<NavigationVisibility>(_currentVisibility);

  @override
  Future<NavigationVisibility> hide() =>
      SynchronousFuture<NavigationVisibility>(_currentVisibility);

  @override
  Future<void> saveVisibility(NavigationVisibility visibility) {
    _currentVisibility = visibility;
    return SynchronousFuture<void>(null);
  }

  @override
  Future<NavigationVisibility> show() =>
      SynchronousFuture<NavigationVisibility>(_currentVisibility);

  @override
  Future<bool> shouldAutoHide(int idleDurationSeconds) =>
      SynchronousFuture<bool>(true);

  @override
  Future<NavigationVisibility> startInteraction() =>
      SynchronousFuture<NavigationVisibility>(_currentVisibility);

  @override
  Stream<NavigationVisibility> watchVisibility() => const Stream.empty();

  @override
  void dispose() {}
}

class _TestLastVisitedPageRepository implements LastVisitedPageRepository {
  _TestLastVisitedPageRepository({this.initialPage});

  final int? initialPage;

  @override
  Future<void> clearLastVisitedPage() async {}

  @override
  Future<int?> getLastVisitedPage() async => initialPage;

  @override
  Future<void> saveLastVisitedPage(int pageNumber) async {}
}
