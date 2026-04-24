import '../../domain/entities/share_video_profile.dart';

enum ShareDurationPreset { auto, short, medium, long }

extension ShareDurationPresetExtension on ShareDurationPreset {
  int? get maxDurationSeconds => switch (this) {
    ShareDurationPreset.auto => null,
    ShareDurationPreset.short => ShareVideoProfile.shortDurationSeconds,
    ShareDurationPreset.medium => ShareVideoProfile.mediumDurationSeconds,
    ShareDurationPreset.long => ShareVideoProfile.longDurationSeconds,
  };
}
