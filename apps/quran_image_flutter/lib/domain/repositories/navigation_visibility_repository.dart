import '../entities/navigation_visibility.dart';

/// Repository interface for navigation visibility operations.
///
/// This abstract class defines the contract for managing navigation
/// control visibility state, including auto-hide timer logic.
abstract class NavigationVisibilityRepository {
  /// Gets the current visibility state
  Future<NavigationVisibility> getVisibility();

  /// Saves the visibility state
  Future<void> saveVisibility(NavigationVisibility visibility);

  /// Shows the navigation controls
  Future<NavigationVisibility> show();

  /// Hides the navigation controls
  Future<NavigationVisibility> hide();

  /// Starts user interaction (prevents auto-hide)
  Future<NavigationVisibility> startInteraction();

  /// Ends user interaction (allows auto-hide)
  Future<NavigationVisibility> endInteraction();

  /// Stream of visibility state changes for reactive UI updates
  Stream<NavigationVisibility> watchVisibility();

  /// Checks if controls should auto-hide based on idle duration
  Future<bool> shouldAutoHide(int idleDurationSeconds);

  /// Releases resources held by this repository.
  void dispose();
}
