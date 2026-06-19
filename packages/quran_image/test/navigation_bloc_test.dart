import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/data/repositories/in_memory_page_repository.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_event.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_state.dart';

void main() {
  group('NavigationBloc', () {
    test('initializes with saved page and visibility state', () async {
      final bloc = NavigationBloc(
        pageRepository: InMemoryPageRepository(),
        visibilityRepository: _TestNavigationVisibilityRepository(
          shouldAutoHideResult: true,
        ),
        saveLastVisitedPageUseCase: SaveLastVisitedPageUseCase(
          _TestLastVisitedPageRepository(),
        ),
        getLastVisitedPageUseCase: GetLastVisitedPageUseCase(
          _TestLastVisitedPageRepository(initialPage: 7),
        ),
      );
      addTearDown(bloc.close);

      bloc.add(const NavigationInitialized());
      await Future<void>.delayed(Duration.zero);

      final state = bloc.state;
      expect(state, isA<NavigationLoaded>());
      final loaded = state as NavigationLoaded;
      expect(loaded.pageState.currentPage, 7);
      expect(loaded.visibility.isVisible, isFalse);
    });

    test('shows, hides, toggles, and tracks interaction', () async {
      final visibilityRepository = _TestNavigationVisibilityRepository(
        shouldAutoHideResult: true,
      );
      final bloc = NavigationBloc(
        pageRepository: InMemoryPageRepository(),
        visibilityRepository: visibilityRepository,
        saveLastVisitedPageUseCase: SaveLastVisitedPageUseCase(
          _TestLastVisitedPageRepository(),
        ),
        getLastVisitedPageUseCase: GetLastVisitedPageUseCase(
          _TestLastVisitedPageRepository(initialPage: 2),
        ),
      );
      addTearDown(bloc.close);

      bloc.add(const NavigationInitialized());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const NavigationShown());
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as NavigationLoaded).visibility.isVisible, isTrue);

      bloc.add(const NavigationInteractionStarted());
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as NavigationLoaded).visibility.isInteracting, isTrue);

      bloc.add(const NavigationInteractionEnded());
      await Future<void>.delayed(Duration.zero);
      expect(
        (bloc.state as NavigationLoaded).visibility.isInteracting,
        isFalse,
      );

      bloc.add(const NavigationToggled());
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as NavigationLoaded).visibility.isVisible, isFalse);

      bloc.add(const NavigationHidden());
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as NavigationLoaded).visibility.isVisible, isFalse);

      expect(
        visibilityRepository.events,
        containsAll(const <String>[
          'show',
          'startInteraction',
          'endInteraction',
          'hide',
        ]),
      );
    });

    test('auto-hides the controls after the idle window elapses', () async {
      final bloc = NavigationBloc(
        pageRepository: InMemoryPageRepository(),
        visibilityRepository: _TestNavigationVisibilityRepository(
          shouldAutoHideResult: true,
        ),
        saveLastVisitedPageUseCase: SaveLastVisitedPageUseCase(
          _TestLastVisitedPageRepository(),
        ),
        getLastVisitedPageUseCase: GetLastVisitedPageUseCase(
          _TestLastVisitedPageRepository(initialPage: 1),
        ),
        autoHideIdleDuration: const Duration(milliseconds: 40),
      );
      addTearDown(bloc.close);

      bloc.add(const NavigationInitialized());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const NavigationShown());
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as NavigationLoaded).visibility.isVisible, isTrue);

      // Still visible before the idle window elapses.
      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect((bloc.state as NavigationLoaded).visibility.isVisible, isTrue);

      // Hidden automatically once idle.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect((bloc.state as NavigationLoaded).visibility.isVisible, isFalse);
    });

    test('interaction defers auto-hide until the gesture ends', () async {
      final bloc = NavigationBloc(
        pageRepository: InMemoryPageRepository(),
        visibilityRepository: _TestNavigationVisibilityRepository(
          shouldAutoHideResult: true,
        ),
        saveLastVisitedPageUseCase: SaveLastVisitedPageUseCase(
          _TestLastVisitedPageRepository(),
        ),
        getLastVisitedPageUseCase: GetLastVisitedPageUseCase(
          _TestLastVisitedPageRepository(initialPage: 1),
        ),
        autoHideIdleDuration: const Duration(milliseconds: 40),
      );
      addTearDown(bloc.close);

      bloc.add(const NavigationInitialized());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const NavigationShown());
      bloc.add(const NavigationInteractionStarted());
      await Future<void>.delayed(Duration.zero);

      // Past the idle window, but still visible because the user is interacting.
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect((bloc.state as NavigationLoaded).visibility.isVisible, isTrue);

      // Ending the interaction re-arms the timer; it hides after the window.
      bloc.add(const NavigationInteractionEnded());
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect((bloc.state as NavigationLoaded).visibility.isVisible, isFalse);
    });

    test('updates current page and persists after debounce', () async {
      final lastVisitedRepository = _TestLastVisitedPageRepository();
      final bloc = NavigationBloc(
        pageRepository: InMemoryPageRepository(),
        visibilityRepository: _TestNavigationVisibilityRepository(
          shouldAutoHideResult: true,
        ),
        saveLastVisitedPageUseCase: SaveLastVisitedPageUseCase(
          lastVisitedRepository,
        ),
        getLastVisitedPageUseCase: GetLastVisitedPageUseCase(
          _TestLastVisitedPageRepository(initialPage: 1),
        ),
      );
      addTearDown(bloc.close);

      bloc.add(const NavigationInitialized());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const PageChanged(9));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = bloc.state as NavigationLoaded;
      expect(state.pageState.currentPage, 9);

      await Future<void>.delayed(const Duration(milliseconds: 550));
      expect(lastVisitedRepository.savedPages, <int>[9]);
    });

    test('emits error on init failure and recovers on retry', () async {
      final repository = _TestLastVisitedPageRepository(
        throwOnGetCount: 1,
        initialPage: 11,
      );
      final bloc = NavigationBloc(
        pageRepository: InMemoryPageRepository(),
        visibilityRepository: _TestNavigationVisibilityRepository(
          shouldAutoHideResult: true,
        ),
        saveLastVisitedPageUseCase: SaveLastVisitedPageUseCase(repository),
        getLastVisitedPageUseCase: GetLastVisitedPageUseCase(repository),
      );
      addTearDown(bloc.close);

      bloc.add(const NavigationInitialized());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<NavigationError>());

      bloc.add(const NavigationRetryRequested());
      await Future<void>.delayed(Duration.zero);

      final state = bloc.state;
      expect(state, isA<NavigationLoaded>());
      expect((state as NavigationLoaded).pageState.currentPage, 11);
    });
  });
}

class _TestNavigationVisibilityRepository
    implements NavigationVisibilityRepository {
  _TestNavigationVisibilityRepository({required this.shouldAutoHideResult});

  final bool shouldAutoHideResult;
  final List<String> events = <String>[];
  NavigationVisibility _currentVisibility = NavigationVisibility.initial();
  final StreamController<NavigationVisibility> _controller =
      StreamController<NavigationVisibility>.broadcast();

  @override
  Future<NavigationVisibility> endInteraction() {
    events.add('endInteraction');
    _currentVisibility = _currentVisibility.copyWith(
      isInteracting: false,
      lastShownAt: DateTime.now(),
    );
    _controller.add(_currentVisibility);
    return SynchronousFuture<NavigationVisibility>(_currentVisibility);
  }

  @override
  Future<NavigationVisibility> getVisibility() =>
      SynchronousFuture<NavigationVisibility>(_currentVisibility);

  @override
  Future<NavigationVisibility> hide() {
    events.add('hide');
    _currentVisibility = _currentVisibility.copyWith(
      isVisible: false,
      clearLastShownAt: true,
    );
    _controller.add(_currentVisibility);
    return SynchronousFuture<NavigationVisibility>(_currentVisibility);
  }

  @override
  Future<void> saveVisibility(NavigationVisibility visibility) {
    _currentVisibility = visibility;
    _controller.add(visibility);
    return SynchronousFuture<void>(null);
  }

  @override
  Future<NavigationVisibility> show() {
    events.add('show');
    _currentVisibility = _currentVisibility.copyWith(
      isVisible: true,
      isInteracting: false,
      lastShownAt: DateTime.now(),
    );
    _controller.add(_currentVisibility);
    return SynchronousFuture<NavigationVisibility>(_currentVisibility);
  }

  @override
  Future<bool> shouldAutoHide(int idleDurationSeconds) =>
      SynchronousFuture<bool>(shouldAutoHideResult);

  @override
  Future<NavigationVisibility> startInteraction() {
    events.add('startInteraction');
    _currentVisibility = _currentVisibility.copyWith(isInteracting: true);
    _controller.add(_currentVisibility);
    return SynchronousFuture<NavigationVisibility>(_currentVisibility);
  }

  @override
  Stream<NavigationVisibility> watchVisibility() => _controller.stream;

  @override
  void dispose() {
    _controller.close();
  }
}

class _TestLastVisitedPageRepository implements LastVisitedPageRepository {
  _TestLastVisitedPageRepository({this.initialPage, this.throwOnGetCount = 0});

  final int? initialPage;
  final int throwOnGetCount;
  final List<int> savedPages = <int>[];
  int _getCallCount = 0;
  int? _lastVisitedPage;

  @override
  Future<void> clearLastVisitedPage() async {
    _lastVisitedPage = null;
  }

  @override
  Future<int?> getLastVisitedPage() async {
    _getCallCount++;
    if (_getCallCount <= throwOnGetCount) {
      throw Exception('get failed');
    }
    return _lastVisitedPage ?? initialPage;
  }

  @override
  Future<void> saveLastVisitedPage(int pageNumber) async {
    savedPages.add(pageNumber);
    _lastVisitedPage = pageNumber;
  }
}
