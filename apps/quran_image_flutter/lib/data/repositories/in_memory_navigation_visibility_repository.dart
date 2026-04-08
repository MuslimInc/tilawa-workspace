import 'dart:async';

import '../../domain/domain.dart';

/// In-memory implementation of [NavigationVisibilityRepository].
///
/// This implementation manages navigation visibility state with
/// auto-hide timer logic and reactive updates.
class InMemoryNavigationVisibilityRepository
    implements NavigationVisibilityRepository {
  NavigationVisibility _currentVisibility = NavigationVisibility.initial();
  final _visibilityController =
      StreamController<NavigationVisibility>.broadcast();

  @override
  Future<NavigationVisibility> getVisibility() async {
    return _currentVisibility;
  }

  @override
  Future<void> saveVisibility(NavigationVisibility visibility) async {
    _currentVisibility = visibility;
    _visibilityController.add(visibility);
  }

  @override
  Future<NavigationVisibility> show() async {
    final newVisibility = _currentVisibility.copyWith(
      isVisible: true,
      lastShownAt: DateTime.now(),
    );
    await saveVisibility(newVisibility);
    return newVisibility;
  }

  @override
  Future<NavigationVisibility> hide() async {
    final newVisibility = _currentVisibility.copyWith(
      isVisible: false,
      lastShownAt: null,
    );
    await saveVisibility(newVisibility);
    return newVisibility;
  }

  @override
  Future<NavigationVisibility> startInteraction() async {
    final newVisibility = _currentVisibility.copyWith(isInteracting: true);
    await saveVisibility(newVisibility);
    return newVisibility;
  }

  @override
  Future<NavigationVisibility> endInteraction() async {
    final newVisibility = _currentVisibility.copyWith(
      isInteracting: false,
      lastShownAt: DateTime.now(), // Reset timer after interaction
    );
    await saveVisibility(newVisibility);
    return newVisibility;
  }

  @override
  Stream<NavigationVisibility> watchVisibility() {
    return _visibilityController.stream;
  }

  @override
  Future<bool> shouldAutoHide(int idleDurationSeconds) async {
    return _currentVisibility.shouldAutoHide(idleDurationSeconds);
  }

  /// Disposes the repository resources
  void dispose() {
    _visibilityController.close();
  }
}
