abstract class DecodedQuranImageCache {
  void prewarmLineImage({required String imagePath, required int cacheWidth});

  void prewarmFileImage(String imagePath);

  /// Returns true if the line image identified by [imagePath] at [cacheWidth]
  /// is fully decoded and resident in Flutter's image cache (keepAlive or live).
  ///
  /// Pending (decode in-flight) is intentionally excluded — jumping while
  /// images are pending causes visible blank lines for several seconds while
  /// the codec finishes decoding.
  ///
  /// This is async because obtaining the correct cache key requires awaiting
  /// [ImageProvider.obtainCacheStatus], which resolves the provider's key
  /// before querying [ImageCache.statusForKey].
  Future<bool> isLineImageCached({
    required String imagePath,
    required int cacheWidth,
  });
}
