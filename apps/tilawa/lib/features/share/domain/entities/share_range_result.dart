import 'package:flutter/foundation.dart';
import '../../presentation/utils/video_page_specs.dart';

@immutable
class ShareRangeResult {
  const ShareRangeResult({
    required this.fromAyah,
    required this.toAyah,
    required this.videoPageSpecs,
  });

  final int fromAyah;
  final int toAyah;
  final List<VideoPageSpec> videoPageSpecs;
}
