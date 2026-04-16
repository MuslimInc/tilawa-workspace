import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';

/// In-memory implementation of [NavigationVisibilityRepository].
///
/// All state mutations are purely synchronous in-memory operations.
/// [SynchronousFuture] is used throughout so that awaiting these methods
/// does not schedule microtasks — the bloc event handlers resume inline
/// without yielding to the event loop. This prevents vsync stalls when
/// rapid taps enqueue many toggle events in quick succession.
class InMemoryNavigationVisibilityRepository
    implements NavigationVisibilityRepository {
  NavigationVisibility _currentVisibility = NavigationVisibility.initial();
  final _visibilityController =
      StreamController<NavigationVisibility>.broadcast();

  @override
  Future<NavigationVisibility> getVisibility() =>
      SynchronousFuture(_currentVisibility);

  @override
  Future<void> saveVisibility(NavigationVisibility visibility) {
    _currentVisibility = visibility;
    _visibilityController.add(visibility);
    return SynchronousFuture(null);
  }

  @override
  Future<NavigationVisibility> show() {
    final newVisibility = _currentVisibility.copyWith(
      isVisible: true,
      lastShownAt: DateTime.now(),
    );
    _currentVisibility = newVisibility;
    _visibilityController.add(newVisibility);
    return SynchronousFuture(newVisibility);
  }

  @override
  Future<NavigationVisibility> hide() {
    final newVisibility = _currentVisibility.copyWith(
      isVisible: false,
      clearLastShownAt: true,
    );
    _currentVisibility = newVisibility;
    _visibilityController.add(newVisibility);
    return SynchronousFuture(newVisibility);
  }

  @override
  Future<NavigationVisibility> startInteraction() {
    final newVisibility = _currentVisibility.copyWith(isInteracting: true);
    _currentVisibility = newVisibility;
    _visibilityController.add(newVisibility);
    return SynchronousFuture(newVisibility);
  }

  @override
  Future<NavigationVisibility> endInteraction() {
    final newVisibility = _currentVisibility.copyWith(
      isInteracting: false,
      lastShownAt: DateTime.now(), // Reset timer after interaction
    );
    _currentVisibility = newVisibility;
    _visibilityController.add(newVisibility);
    return SynchronousFuture(newVisibility);
  }

  @override
  Stream<NavigationVisibility> watchVisibility() {
    return _visibilityController.stream;
  }

  @override
  Future<bool> shouldAutoHide(int idleDurationSeconds) =>
      SynchronousFuture(_currentVisibility.shouldAutoHide(idleDurationSeconds));

  @override
  void dispose() {
    _visibilityController.close();
  }
}
