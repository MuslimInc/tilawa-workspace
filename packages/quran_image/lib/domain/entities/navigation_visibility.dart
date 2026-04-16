import 'package:equatable/equatable.dart';

/// Represents the visibility state of the navigation controls.
///
/// This entity manages whether the navigation slider and controls are
/// visible or hidden, along with the auto-hide timer state.
class NavigationVisibility extends Equatable {
  /// Whether the navigation controls are currently visible
  final bool isVisible;

  /// Whether the user is currently interacting (prevents auto-hide)
  final bool isInteracting;

  /// Time when the controls were last shown (for auto-hide calculation)
  final DateTime? lastShownAt;

  const NavigationVisibility({
    required this.isVisible,
    this.isInteracting = false,
    this.lastShownAt,
  });

  /// Creates an initial state with controls hidden
  factory NavigationVisibility.initial() {
    return const NavigationVisibility(
      isVisible: false,
      isInteracting: false,
      lastShownAt: null,
    );
  }

  /// Creates a copy with modified fields
  /// Creates a copy with modified fields.
  ///
  /// Set [clearLastShownAt] to `true` to explicitly reset
  /// [lastShownAt] to `null` (the `??` operator cannot do this).
  NavigationVisibility copyWith({
    bool? isVisible,
    bool? isInteracting,
    DateTime? lastShownAt,
    bool clearLastShownAt = false,
  }) {
    return NavigationVisibility(
      isVisible: isVisible ?? this.isVisible,
      isInteracting: isInteracting ?? this.isInteracting,
      lastShownAt: clearLastShownAt ? null : (lastShownAt ?? this.lastShownAt),
    );
  }

  /// Returns true if the controls should auto-hide based on idle duration
  bool shouldAutoHide(int idleDurationSeconds) {
    if (!isVisible || isInteracting) return false;
    final lastShown = lastShownAt;
    if (lastShown == null) return false;
    final elapsed = DateTime.now().difference(lastShown).inSeconds;
    return elapsed >= idleDurationSeconds;
  }

  @override
  List<Object?> get props => [isVisible, isInteracting, lastShownAt];
}
