import 'package:meta/meta.dart';

/// Source of "now" for prayer-time comparisons and UI that depends on it.
///
/// Production uses [DateTime.now]. Tests may call [overrideForTesting] so
/// layouts (e.g. golden tests) stay stable across machines and run times.
abstract final class PrayerTimesClock {
  static DateTime Function()? _overrideForTesting;

  static DateTime now() => _overrideForTesting?.call() ?? DateTime.now();

  @visibleForTesting
  static void overrideForTesting(DateTime Function() value) {
    _overrideForTesting = value;
  }

  @visibleForTesting
  static void clearTestingOverride() {
    _overrideForTesting = null;
  }
}
