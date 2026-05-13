import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// In-session payload for [ScreenshotComposerRoute] (not JSON-restorable).
@immutable
class ScreenshotComposerNavExtra {
  const ScreenshotComposerNavExtra({
    required this.surahNumber,
    required this.currentPage,
    required this.initialFromAyah,
    required this.initialToAyah,
    required this.reciterName,
    required this.readerBoundaryKey,
    this.readerPreviewBytesNotifier,
  });

  final int surahNumber;
  final int currentPage;
  final int initialFromAyah;
  final int initialToAyah;
  final String reciterName;
  final GlobalKey readerBoundaryKey;
  final ValueListenable<Uint8List?>? readerPreviewBytesNotifier;
}

/// In-session payload for [VideoReelComposerRoute] (not JSON-restorable).
@immutable
class VideoReelComposerNavExtra {
  const VideoReelComposerNavExtra({
    required this.surahNumber,
    required this.initialFromAyah,
    required this.initialToAyah,
    required this.reciterName,
    required this.reciterServerUrl,
  });

  final int surahNumber;
  final int initialFromAyah;
  final int initialToAyah;
  final String reciterName;
  final String reciterServerUrl;
}
