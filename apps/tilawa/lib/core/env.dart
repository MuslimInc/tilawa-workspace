/// Compile-time build flags.
///
/// Each flag here is read via `bool.fromEnvironment` so production builds
/// can dead-code-eliminate the gated UI. Toggle with `--dart-define=<NAME>=true`
/// at build time (e.g. in dev/QA `flutter run --dart-define=...`).
abstract final class Env {
  Env._();

  /// Whether the user-facing primary color picker is shown in Settings.
  ///
  /// Production: **false**. Tilawa's brand color is fixed (Sage `#219653`
  /// accent on `#E5E7EB` neutral, per `docs/tilawa_brand.md` §3); users do
  /// not pick a brand color. The picker is retained behind this flag for
  /// internal dev/QA palette work — pass
  /// `--dart-define=TILAWA_SHOW_COLOR_PICKER=true` to enable.
  static const bool kShowColorPicker = bool.fromEnvironment(
    'TILAWA_SHOW_COLOR_PICKER',
  );
}
