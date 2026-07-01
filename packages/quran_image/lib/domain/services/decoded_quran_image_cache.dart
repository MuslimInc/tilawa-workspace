import 'package:flutter/painting.dart';

abstract class DecodedQuranImageCache {
  /// Returns the shared [ImageProvider] used for line paint and prewarm.
  ImageProvider<Object> lineImageProvider({
    required String imagePath,
    required int cacheWidth,
  });

  /// Returns the shared [ImageProvider] used for non-line file paint and prewarm.
  ImageProvider<Object> fileImageProvider({required String imagePath});

  Future<void> prewarmLineImage({
    required String imagePath,
    required int cacheWidth,
  });

  Future<void> prewarmFileImage(String imagePath);

  void handleMemoryPressure();
}
