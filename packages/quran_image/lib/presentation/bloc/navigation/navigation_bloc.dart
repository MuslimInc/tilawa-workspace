import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/perf_logger.dart';
import '../../../domain/domain.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

/// BLoC for managing navigation state and visibility.
///
/// This BLoC handles:
/// - Page state synchronization after PageView settles
/// - Navigation visibility (show/hide)
/// - Auto-hide timer logic
/// - User interaction tracking
/// - Persisting last visited page
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  static bool _quranPerfOverlayFirstOpenLogged = false;

  /// Default idle time the controls stay visible before auto-hiding so the page
  /// is returned to a fully readable, unobstructed state. Reading is the
  /// default; the controls are a transient layer summoned to navigate, then they
  /// get out of the way on their own — no tap-to-dismiss required, no text left
  /// covered. Overridable via the constructor for testing.
  static const Duration defaultAutoHideIdleDuration = Duration(seconds: 4);

  final Duration _autoHideIdleDuration;

  final PageRepository _pageRepository;
  final NavigationVisibilityRepository _visibilityRepository;
  final SaveLastVisitedPageUseCase _saveLastVisitedPageUseCase;
  final GetLastVisitedPageUseCase _getLastVisitedPageUseCase;

  /// Pending auto-hide. Armed whenever the controls become visible and idle,
  /// cancelled when they hide or the user starts interacting.
  Timer? _autoHideTimer;

  NavigationBloc({
    PageRepository? pageRepository,
    NavigationVisibilityRepository? visibilityRepository,
    SaveLastVisitedPageUseCase? saveLastVisitedPageUseCase,
    GetLastVisitedPageUseCase? getLastVisitedPageUseCase,
    Duration? autoHideIdleDuration,
  }) : _autoHideIdleDuration =
           autoHideIdleDuration ?? defaultAutoHideIdleDuration,
       _pageRepository = pageRepository ?? sl<PageRepository>(),
       _visibilityRepository =
           visibilityRepository ?? sl<NavigationVisibilityRepository>(),
       _saveLastVisitedPageUseCase =
           saveLastVisitedPageUseCase ?? sl<SaveLastVisitedPageUseCase>(),
       _getLastVisitedPageUseCase =
           getLastVisitedPageUseCase ?? sl<GetLastVisitedPageUseCase>(),
       super(const NavigationInitial()) {
    on<NavigationInitialized>(_onInitialized);
    on<NavigationShown>(_onShown);
    on<NavigationHidden>(_onHidden);
    on<NavigationToggled>(_onToggled);
    on<NavigationInteractionStarted>(_onInteractionStarted);
    on<NavigationInteractionEnded>(_onInteractionEnded);
    on<PageChanged>(_onPageChanged);
    on<LastVisitedPageSaved>(_onLastVisitedPageSaved);
    on<NavigationRetryRequested>(_onRetryRequested);
  }

  Future<void> _onInitialized(
    NavigationInitialized event,
    Emitter<NavigationState> emit,
  ) async {
    emit(const NavigationLoading());
    try {
      // Get the requested initial page or fall back to last visited page (or page 1)
      final savedPage =
          event.initialPage ??
          await _getLastVisitedPageUseCase.executeOrDefault(1);
      final pageState = _pageRepository.navigateToPage(savedPage);
      final visibility = await _visibilityRepository.getVisibility();
      emit(NavigationLoaded(pageState: pageState, visibility: visibility));
    } catch (e) {
      emit(const NavigationError(NavigationInitFailedMessage()));
    }
  }

  // Visibility handlers are intentionally non-async.
  //
  // InMemoryNavigationVisibilityRepository returns SynchronousFuture from all
  // methods. SynchronousFuture delivers its value synchronously to .then()
  // callbacks — no microtask is scheduled. Using `await` inside an `async`
  // function always suspends and posts a microtask resumption even when the
  // awaited future is already complete. For rapid tap sequences that enqueue
  // many NavigationToggled events, those microtask resumptions back up and
  // delay the next vsync callback by 50-100ms.
  //
  // By using .then() in a non-async handler we avoid the async suspension
  // entirely: the repository call, emit, and timer call all happen on the
  // same event-loop turn as the BLoC event dispatch.

  /// (Re)arms the auto-hide timer for a visibility snapshot. The controls hide
  /// themselves after [_autoHideIdleDuration] of no interaction so the page is
  /// left unobstructed. Does nothing while the user is actively interacting —
  /// [_onInteractionEnded] re-arms it once the gesture finishes.
  void _scheduleAutoHide(NavigationVisibility visibility) {
    _autoHideTimer?.cancel();
    if (!visibility.isVisible || visibility.isInteracting) {
      return;
    }
    _autoHideTimer = Timer(_autoHideIdleDuration, () {
      if (isClosed) return;
      add(const NavigationHidden());
    });
  }

  void _cancelAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
  }

  void _onShown(NavigationShown event, Emitter<NavigationState> emit) {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      final wasVisible = currentState.visibility.isVisible;
      _visibilityRepository.show().then((visibility) {
        _logQuranOverlayTransition(
          wasVisible: wasVisible,
          visibility: visibility,
        );
        emit(currentState.copyWith(visibility: visibility));
        _scheduleAutoHide(visibility);
      });
    }
  }

  void _onHidden(NavigationHidden event, Emitter<NavigationState> emit) {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      final wasVisible = currentState.visibility.isVisible;
      _cancelAutoHide();
      _visibilityRepository.hide().then((visibility) {
        _logQuranOverlayTransition(
          wasVisible: wasVisible,
          visibility: visibility,
        );
        emit(currentState.copyWith(visibility: visibility));
      });
    }
  }

  void _onToggled(NavigationToggled event, Emitter<NavigationState> emit) {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      final wasVisible = currentState.visibility.isVisible;
      if (currentState.visibility.isVisible) {
        _cancelAutoHide();
        _visibilityRepository.hide().then((visibility) {
          _logQuranOverlayTransition(
            wasVisible: wasVisible,
            visibility: visibility,
          );
          emit(currentState.copyWith(visibility: visibility));
        });
      } else {
        _visibilityRepository.show().then((visibility) {
          _logQuranOverlayTransition(
            wasVisible: wasVisible,
            visibility: visibility,
          );
          emit(currentState.copyWith(visibility: visibility));
          _scheduleAutoHide(visibility);
        });
      }
    }
  }

  void _logQuranOverlayTransition({
    required bool wasVisible,
    required NavigationVisibility visibility,
  }) {
    if (!PerfLogger.isQuranPerfEnabled) return;
    final nowVisible = visibility.isVisible;
    if (!wasVisible && nowVisible) {
      if (!_quranPerfOverlayFirstOpenLogged) {
        _quranPerfOverlayFirstOpenLogged = true;
        PerfLogger.logQuranPerf('[QuranPerf][Overlay]', 'firstOpen');
      }
      PerfLogger.logQuranPerf('[QuranPerf][Overlay]', 'shown');
    } else if (wasVisible && !nowVisible) {
      PerfLogger.logQuranPerf('[QuranPerf][Overlay]', 'hidden');
    }
  }

  void _onInteractionStarted(
    NavigationInteractionStarted event,
    Emitter<NavigationState> emit,
  ) {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      // Hold the controls open while the user is scrubbing the slider or
      // pressing the arrows.
      _cancelAutoHide();
      _visibilityRepository.startInteraction().then((visibility) {
        emit(currentState.copyWith(visibility: visibility));
      });
    }
  }

  void _onInteractionEnded(
    NavigationInteractionEnded event,
    Emitter<NavigationState> emit,
  ) {
    final currentState = state;
    if (currentState is NavigationLoaded) {
      _visibilityRepository.endInteraction().then((visibility) {
        emit(currentState.copyWith(visibility: visibility));
        // Restart the idle countdown now that the interaction is over.
        _scheduleAutoHide(visibility);
      });
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
        PerfLogger.log(
          widgetName: 'NavigationBloc',
          message:
              'page changed from=${currentState.pageState.currentPage} '
              'to=${event.pageNumber}',
        );
        final pageState = _pageRepository.navigateToPage(event.pageNumber);
        emit(currentState.copyWith(pageState: pageState));
        // Persist the newly visited page
        add(LastVisitedPageSaved(event.pageNumber));
      }
    }
  }

  Future<void> _onLastVisitedPageSaved(
    LastVisitedPageSaved event,
    Emitter<NavigationState> emit,
  ) async {
    // Persistence is now immediate as timers are removed.
    try {
      await _saveLastVisitedPageUseCase.execute(event.pageNumber);
    } catch (e, stackTrace) {
      developer.log(
        'failed to save last visited page',
        name: 'NavigationBloc',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onRetryRequested(
    NavigationRetryRequested event,
    Emitter<NavigationState> emit,
  ) async {
    await _onInitialized(const NavigationInitialized(), emit);
  }

  @override
  Future<void> close() {
    _cancelAutoHide();
    return super.close();
  }
}
