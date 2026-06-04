const bool kReelComposerV2 = bool.fromEnvironment('REEL_COMPOSER_V2');
const bool kReelComposerSingleTree = bool.fromEnvironment(
  'REEL_COMPOSER_SINGLE_TREE',
);

/// When false (default), native FFmpeg is not shipped; share reel encoding is
/// frozen and [DisabledFfmpegRunner] is bound in DI. Set via
/// `--dart-define=SHARE_FFMPEG_ENABLED=true` after re-adding the plugin.
const bool kShareFfmpegNativeEnabled = bool.fromEnvironment(
  'SHARE_FFMPEG_ENABLED',
);

/// Video reel UI and navigation. Mirrors [kShareFfmpegNativeEnabled].
const bool kShareVideoReelEnabled = kShareFfmpegNativeEnabled;

/// Screenshot share UI and navigation. Frozen by default: the screenshot
/// composer route carries a non-serializable `extra` (a GlobalKey/Notifier),
/// so keeping its entry points hidden removes that navigation path entirely.
/// Enable with `--dart-define=SHARE_SCREENSHOT_ENABLED=true`.
const bool kShareScreenshotEnabled = bool.fromEnvironment(
  'SHARE_SCREENSHOT_ENABLED',
);
