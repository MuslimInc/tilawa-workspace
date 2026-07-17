import 'package:flutter/painting.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Predefined primary-color options offered to the user in Settings.
///
/// The single source of truth for the app's default primary color is
/// [defaultPreset]. The static palette in [AppColors] is referenced for
/// concrete values, but the runtime "what is the default" concept lives here.
enum PrimaryColorPreset {
  coral(id: 'coral', value: AppColors.primaryCoral),
  teal(id: 'teal', value: AppColors.primaryTeal),
  sage(id: 'sage', value: AppColors.primarySage),
  gold(id: 'gold', value: AppColors.primaryGold),
  brandOrange(id: 'brand_orange', value: AppColors.brandActionOrange),
  ink(id: 'ink', value: AppColors.tripGlideInk);

  const PrimaryColorPreset({required this.id, required this.value});

  /// Stable identifier used for persistence. Does not change when the enum
  /// member is renamed.
  final String id;

  /// The concrete color rendered for this preset.
  final Color value;

  /// ARGB value matching [value], for layers that avoid a [Color] type.
  int get valueArgb => value.toARGB32();

  /// Default primary preset for fresh installs and corrupt-payload fallback.
  ///
  /// Brand-locked to orange global accent (`#FA5B2E`) for the MeMuslim palette
  /// system (see `Env.kShowColorPicker`).
  static const PrimaryColorPreset defaultPreset =
      PrimaryColorPreset.brandOrange;

  /// Alias for [defaultPreset]. Use this name at call sites whose intent is
  /// "I want the immutable brand color," so readers don't have to know that
  /// the default preset *is* the brand-locked preset.
  static const PrimaryColorPreset brandLocked = PrimaryColorPreset.brandOrange;

  /// Compatibility alias for [brandOrange] (pre-orange rebrand name).
  static const PrimaryColorPreset brandGreen = PrimaryColorPreset.brandOrange;

  /// Deprecated purple preset id — migrates to [brandOrange].
  static const String legacyPurplePresetId = 'purple';

  /// Deprecated brown preset id — migrates to [brandOrange].
  static const String legacyBrownPresetId = 'brown';

  /// Deprecated brand-green preset id — migrates to [brandOrange].
  static const String legacyBrandGreenPresetId = 'brand_green';

  /// Deprecated purple primary ARGB — migrates to [brandOrange].
  static const int legacyPurplePrimaryArgb = 0xFF7A5C89;

  /// Deprecated brown primary ARGB — migrates to [brandOrange].
  static const int legacyBrownPrimaryArgb = 0xFF8B5E3C;

  /// Retired brand green ARGB (`#2B8659`) — migrates to [brandOrange].
  static const int legacyBrandGreenPrimaryArgb = 0xFF2B8659;

  /// Retired production green ARGB (`#1DAB61`) — migrates to [brandOrange].
  static const int legacyActionGreenPrimaryArgb = 0xFF1DAB61;

  static PrimaryColorPreset? findById(String? id) {
    if (id == null) return null;
    if (id == legacyPurplePresetId ||
        id == legacyBrownPresetId ||
        id == legacyBrandGreenPresetId) {
      return brandOrange;
    }
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }

  static PrimaryColorPreset? findByArgb(int argb) {
    if (argb == legacyPurplePrimaryArgb ||
        argb == legacyBrownPrimaryArgb ||
        argb == legacyBrandGreenPrimaryArgb ||
        argb == legacyActionGreenPrimaryArgb) {
      return brandOrange;
    }
    for (final p in values) {
      if (p.value.toARGB32() == argb) return p;
    }
    return null;
  }

  /// Normalizes a stored primary ARGB, remapping deprecated purple/brown and
  /// retired greens to the current brand orange.
  static int migrateLegacyPrimaryArgb(int argb) {
    if (argb == legacyPurplePrimaryArgb ||
        argb == legacyBrownPrimaryArgb ||
        argb == legacyBrandGreenPrimaryArgb ||
        argb == legacyActionGreenPrimaryArgb) {
      return brandOrange.valueArgb;
    }
    return argb;
  }
}
