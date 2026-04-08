import 'dart:async';
import 'package:flutter/material.dart';

class ImageSize {
  final double width;
  final double height;
  ImageSize(this.width, this.height);
}

class ImageSizeService {
  final Map<String, ImageSize> _cache = {};

  Future<ImageSize> resolveAssetSize(String assetPath) async {
    if (_cache.containsKey(assetPath)) return _cache[assetPath]!;

    final Completer<ImageSize> completer = Completer();
    final ImageStream stream = AssetImage(
      assetPath,
    ).resolve(ImageConfiguration.empty);

    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        final size = ImageSize(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        _cache[assetPath] = size;
        completer.complete(size);
        stream.removeListener(listener);
      },
      onError: (Object exception, StackTrace? stackTrace) {
        completer.completeError(exception, stackTrace);
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
    return completer.future;
  }
}

final imageSizeService = ImageSizeService();
