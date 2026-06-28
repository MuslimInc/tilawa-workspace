/// Stable Semantics identifiers for the TilawaCard nested-tap Maestro demo.
///
/// Referenced by `.maestro/tilawa_card_*.yaml`. Do not rename without updating
/// those flows.
abstract final class TilawaCardDemoSemanticsIds {
  /// Developer settings entry that opens [TilawaCardNestedTapDemoScreen].
  static const String settingsTile = 'tilawa_card_demo_settings_tile';

  /// Root marker on the demo screen (AppBar title region).
  static const String screen = 'tilawa_card_demo_screen';

  /// Last tap outcome label (`idle`, `parent navigated`, `nested play`, …).
  static const String result = 'tilawa_card_demo_result';

  /// Clears the outcome back to `idle`.
  static const String reset = 'tilawa_card_demo_reset';

  /// Non-interactive card body; parent [TilawaCard.onTap] should fire.
  static const String blankArea = 'tilawa_card_demo_blank_area';

  /// Enabled nested play control.
  static const String enabledPlay = 'tilawa_card_demo_enabled_play';

  /// Enabled nested delete control.
  static const String enabledDelete = 'tilawa_card_demo_enabled_delete';

  /// Enabled nested favorite control.
  static const String enabledFavorite = 'tilawa_card_demo_enabled_favorite';

  /// Disabled nested control (dead zone).
  static const String disabledControl = 'tilawa_card_demo_disabled_control';

  /// Decorative [InkWell] with `onTap: null`; parent should receive the tap.
  static const String decorativeInkWell =
      'tilawa_card_demo_decorative_ink_well';

  /// Handler-less [GestureDetector]; parent should receive the tap.
  static const String decorativeGestureDetector =
      'tilawa_card_demo_decorative_gesture_detector';
}
