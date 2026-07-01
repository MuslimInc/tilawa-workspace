import 'package:flutter/painting.dart';
import 'package:quran_image/core/di/dependency_injection.dart';
import 'package:quran_image/domain/services/decoded_quran_image_cache.dart';

/// Builds a [ResizeImage] provider for a Quran line file via [DecodedQuranImageCache].
ImageProvider<Object> buildQuranLineImageProvider({
  required String imagePath,
  required int cacheWidth,
}) {
  return sl<DecodedQuranImageCache>().lineImageProvider(
    imagePath: imagePath,
    cacheWidth: cacheWidth,
  );
}

/// Returns a cached [FileImage] or [ResizeImage] via [DecodedQuranImageCache].
ImageProvider<Object> cachedFileImageProvider({
  required String imagePath,
  int? cacheWidth,
}) {
  final cache = sl<DecodedQuranImageCache>();
  if (cacheWidth == null) {
    return cache.fileImageProvider(imagePath: imagePath);
  }
  return cache.lineImageProvider(
    imagePath: imagePath,
    cacheWidth: cacheWidth,
  );
}
