import 'package:meta/meta.dart';

/// When `true`, [PrayerTimesScreen] shows the centered loading spinner so you
/// can capture screenshots (design review, sharing layouts, store prep).
///
/// **Release / normal runs:** omit the define (defaults to `false`).
///
/// ```sh
/// flutter run --dart-define=PRAYER_TIMES_LOADING_PREVIEW=true
/// ```
///
/// Same for a release-mode device build if needed:
///
/// ```sh
/// flutter run --release --dart-define=PRAYER_TIMES_LOADING_PREVIEW=true
/// ```
abstract final class PrayerTimesScreenLoadingPreview {
  static const bool _compileTimeEnabled = bool.fromEnvironment(
    'PRAYER_TIMES_LOADING_PREVIEW',
    defaultValue: false,
  );

  /// Replaces the compile-time flag (widget tests only).
  @visibleForTesting
  static bool? debugOverride;

  static bool get enabled => debugOverride ?? _compileTimeEnabled;
}
