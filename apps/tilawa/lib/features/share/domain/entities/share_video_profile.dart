abstract final class ShareVideoProfile {
  static const int outputWidthPx = 720;
  static const int outputHeightPx = 1280;
  static const double outputWidth = outputWidthPx * 1.0;
  static const double outputHeight = outputHeightPx * 1.0;
  static const int outputFps = 30;
  static const int stillImageInputFps = 1;
  static const int keyframeIntervalSeconds = 2;
  static const int keyframeIntervalFrames = outputFps * keyframeIntervalSeconds;
  static const int shortDurationSeconds = 30;
  static const int mediumDurationSeconds = 60;
  static const int longDurationSeconds = 90;
  static const String audioBitrate = '128k';
  static const double aspectRatio = outputWidthPx / outputHeightPx;
  static const double fallbackSecondsPerSlide = longDurationSeconds * 1.0;
}
