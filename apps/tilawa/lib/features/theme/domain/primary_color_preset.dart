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
  brown(id: 'brown', value: AppColors.primaryBrown),
  purple(id: 'purple', value: AppColors.primaryPurple);

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
  /// Brand-locked to Sage so the user-visible accent stays consistent with
  /// the Islamic-brand direction (see `docs/tilawa_brand.md` §3 and
  /// `Env.kShowColorPicker`). Legacy installs with a different stored preset
  /// continue to deserialize their stored value; the production runtime
  /// override lives in [ThemeStateMaterial.primaryColor].
  static const PrimaryColorPreset defaultPreset = PrimaryColorPreset.sage;

  /// Alias for [defaultPreset]. Use this name at call sites whose intent is
  /// "I want the immutable brand color," so readers don't have to know that
  /// the default preset *is* the brand-locked preset.
  static const PrimaryColorPreset brandLocked = PrimaryColorPreset.sage;

  static PrimaryColorPreset? findById(String? id) {
    if (id == null) return null;
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }

  static PrimaryColorPreset? findByArgb(int argb) {
    for (final p in values) {
      if (p.value.toARGB32() == argb) return p;
    }
    return null;
  }
}
