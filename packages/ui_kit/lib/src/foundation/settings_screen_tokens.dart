/// Layout sizes for the app settings screen (profile card, pickers).
abstract final class TilawaSettingsScreenTokens {
  TilawaSettingsScreenTokens._();

  /// Profile card avatar diameter.
  static const double profileAvatarSize = 60;

  /// Person icon inside the profile avatar.
  static const double profilePersonIconSize = 32;

  /// [CircleAvatar] radius for preset color swatches in the primary picker.
  static const double primaryPickerPresetSwatchRadius = 12;

  /// Custom primary row swatch diameter (matches preset swatch size).
  static const double primaryPickerCustomSwatchSize = 24;

  /// Upper inclusive bound for concurrent-download options (1…N).
  static const int maxConcurrentDownloadsPickerCount = 5;
}
