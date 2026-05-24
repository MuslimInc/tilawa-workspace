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
  static const PrimaryColorPreset defaultPreset = PrimaryColorPreset.coral;

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
