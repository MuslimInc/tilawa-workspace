abstract class DecodedQuranImageCache {
  Future<void> prewarmLineImage({
    required String imagePath,
    required int cacheWidth,
  });

  Future<void> prewarmFileImage(String imagePath);

  void handleMemoryPressure();
}
