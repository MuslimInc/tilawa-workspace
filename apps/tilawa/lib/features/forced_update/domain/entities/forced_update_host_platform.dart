/// Host platform for selecting the remote min build number.
///
/// Kept free of Flutter/`dart:io` so the evaluator stays pure and testable.
enum ForcedUpdateHostPlatform {
  android,
  ios,
  other,
}
