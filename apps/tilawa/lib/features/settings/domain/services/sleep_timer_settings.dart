/// Domain-level abstraction for sleep timer settings.
///
/// Allows audio features to observe sleep timer state without coupling
/// to the settings presentation layer.
abstract class SleepTimerSettings {
  /// Stream of whether the sleep timer feature is enabled.
  Stream<bool> get isSleepTimerEnabledStream;
}
