enum ShareDurationPreset { auto, short, medium, long }

extension ShareDurationPresetExtension on ShareDurationPreset {
  int? get maxDurationSeconds => switch (this) {
    ShareDurationPreset.auto => null,
    ShareDurationPreset.short => 30,
    ShareDurationPreset.medium => 60,
    ShareDurationPreset.long => 90,
  };
}
