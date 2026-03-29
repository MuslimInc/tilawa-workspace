/// Service responsible for managing the screen's "keep awake" state.
/// This prevents the screen from dimming or turning off during active reading.
abstract class KeepAwakeService {
  /// Enables the "keep awake" state.
  Future<void> enable();

  /// Disables the "keep awake" state, returning to system defaults.
  Future<void> disable();

  /// Whether the "keep awake" state is currently enabled.
  Future<bool> get isEnabled;
}
