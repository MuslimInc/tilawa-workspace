import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_tokens/design_tokens.dart';
import '../../../data/data.dart';
import '../../../domain/domain.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

/// BLoC for managing navigation state and visibility.
///
/// This BLoC handles:
/// - Page navigation (next, previous, jump to page)
/// - Navigation visibility (show/hide)
/// - Auto-hide timer logic
/// - User interaction tracking
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final PageRepository _pageRepository;
  final NavigationVisibilityRepository _visibilityRepository;
  Timer? _autoHideTimer;

  NavigationBloc({
    PageRepository? pageRepository,
    NavigationVisibilityRepository? visibilityRepository,
  }) : _pageRepository = pageRepository ?? InMemoryPageRepository(),
       _visibilityRepository =
           visibilityRepository ?? InMemoryNavigationVisibilityRepository(),
       super(const NavigationInitial()) {
    on<NavigationInitialized>(_onInitialized);
    on<NavigationShown>(_onShown);
    on<NavigationHidden>(_onHidden);
    on<NavigationToggled>(_onToggled);
    on<NavigationInteractionStarted>(_onInteractionStarted);
    on<NavigationInteractionEnded>(_onInteractionEnded);
    on<NavigationAutoHideChecked>(_onAutoHideChecked);
    on<PagePreviewed>(_onPagePreviewed);
    on<PageNavigated>(_onPageNavigated);
    on<NextPageRequested>(_onNextPageRequested);
    on<PreviousPageRequested>(_onPreviousPageRequested);
    on<PageChanged>(_onPageChanged);
  }

  Future<void> _onInitialized(
    NavigationInitialized event,
    Emitter<NavigationState> emit,
  ) async {
    emit(const NavigationLoading());
    try {
      final pageState = await _pageRepository.getCurrentPage();
      final visibility = await _visibilityRepository.getVisibility();
      emit(NavigationLoaded(pageState: pageState, visibility: visibility));
      _startAutoHideTimer();
    } catch (e) {
      emit(NavigationError('Failed to initialize navigation: $e'));
    }
  }

  Future<void> _onShown(
    NavigationShown event,
    Emitter<NavigationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      final visibility = await _visibilityRepository.show();
      emit(currentState.copyWith(visibility: visibility));
      _startAutoHideTimer();
    }
  }

  Future<void> _onHidden(
    NavigationHidden event,
    Emitter<NavigationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      final visibility = await _visibilityRepository.hide();
      emit(currentState.copyWith(visibility: visibility));
      _cancelAutoHideTimer();
    }
  }

  Future<void> _onToggled(
    NavigationToggled event,
    Emitter<NavigationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      if (currentState.visibility.isVisible) {
        // Hide if currently visible
        final visibility = await _visibilityRepository.hide();
        emit(currentState.copyWith(visibility: visibility));
        _cancelAutoHideTimer();
      } else {
        // Show if currently hidden
        final visibility = await _visibilityRepository.show();
        emit(currentState.copyWith(visibility: visibility));
        _startAutoHideTimer();
      }
    }
  }

  Future<void> _onInteractionStarted(
    NavigationInteractionStarted event,
    Emitter<NavigationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      final visibility = await _visibilityRepository.startInteraction();
      emit(currentState.copyWith(visibility: visibility));
      _cancelAutoHideTimer(); // Pause timer during interaction
    }
  }

  Future<void> _onInteractionEnded(
    NavigationInteractionEnded event,
    Emitter<NavigationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      final visibility = await _visibilityRepository.endInteraction();
      emit(currentState.copyWith(visibility: visibility));
      _startAutoHideTimer(); // Resume timer after interaction
    }
  }

  Future<void> _onAutoHideChecked(
    NavigationAutoHideChecked event,
    Emitter<NavigationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      final shouldHide = await _visibilityRepository.shouldAutoHide(
        AppDurations.sliderAutoHideSeconds,
      );
      if (shouldHide) {
        final visibility = await _visibilityRepository.hide();
        emit(currentState.copyWith(visibility: visibility));
      }
    }
  }

  Future<void> _onPagePreviewed(
    PagePreviewed event,
    Emitter<NavigationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      // Only update preview without navigating
      final newPageState = currentState.pageState.copyWith(
        previewPage: event.pageNumber,
      );
      emit(currentState.copyWith(pageState: newPageState));
    }
  }

  Future<void> _onPageNavigated(
    PageNavigated event,
    Emitter<NavigationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      try {
        final pageState = await _pageRepository.navigateToPage(
          event.pageNumber,
        );
        // Clear preview after actual navigation
        emit(
          currentState.copyWith(
            pageState: pageState.copyWith(previewPage: null),
          ),
        );
      } catch (e) {
        emit(NavigationError('Invalid page number: ${event.pageNumber}'));
      }
    }
  }

  Future<void> _onNextPageRequested(
    NextPageRequested event,
    Emitter<NavigationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      final pageState = await _pageRepository.nextPage();
      emit(currentState.copyWith(pageState: pageState));
    }
  }

  Future<void> _onPreviousPageRequested(
    PreviousPageRequested event,
    Emitter<NavigationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      final pageState = await _pageRepository.previousPage();
      emit(currentState.copyWith(pageState: pageState));
    }
  }

  Future<void> _onPageChanged(
    PageChanged event,
    Emitter<NavigationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      // Only update if page actually changed
      if (currentState.pageState.currentPage != event.pageNumber) {
        final pageState = await _pageRepository.navigateToPage(
          event.pageNumber,
        );
        emit(currentState.copyWith(pageState: pageState));
      }
    }
  }

  void _startAutoHideTimer() {
    _cancelAutoHideTimer();
    _autoHideTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const NavigationAutoHideChecked()),
    );
  }

  void _cancelAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
  }

  @override
  Future<void> close() {
    _cancelAutoHideTimer();
    return super.close();
  }
}
