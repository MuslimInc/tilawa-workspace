/// Defines the primary modes for sharing Quranic content.
enum ShareMode {
  /// Captures a static image of the Quran page or passage.
  screenshot,

  /// Generates an audio clip for a specific ayah range.
  audio,

  /// Generates a high-quality video (formerly "reel") with synchronized text.
  video
  ;

  /// The list of share modes currently enabled in the application.
  /// To enable/disable a mode, modify this list.
  static List<ShareMode> get supportedModes => [screenshot, video];
}
