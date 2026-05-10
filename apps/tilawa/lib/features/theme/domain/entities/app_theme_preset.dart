enum AppThemePreset {
  defaultMode,
  highContrast,
  trueBlack
  ;

  String get displayName {
    return switch (this) {
      AppThemePreset.defaultMode => 'Default',
      AppThemePreset.highContrast => 'High Contrast',
      AppThemePreset.trueBlack => 'True Black (OLED)',
    };
  }
}
