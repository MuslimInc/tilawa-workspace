import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';

const int _maxFileImageProviderEntries = 1024;
final LinkedHashMap<String, ImageProvider<Object>> _fileImageProviderCache =
    LinkedHashMap<String, ImageProvider<Object>>();

/// Builds a [ResizeImage] provider for a Quran line file.
///
/// Uses an internal LRU cache to avoid a ResizeImage allocation and
/// LRU map lookup on every frame during PageView scrolling.
ImageProvider<Object> buildQuranLineImageProvider({
  required String imagePath,
  required int cacheWidth,
}) {
  return cachedFileImageProvider(imagePath: imagePath, cacheWidth: cacheWidth);
}

/// Returns a [FileImage] or [ResizeImage] with LRU caching.
ImageProvider<Object> cachedFileImageProvider({
  required String imagePath,
  int? cacheWidth,
}) {
  final key = cacheWidth == null ? 'file:$imagePath' : '$cacheWidth:$imagePath';
  final cached = _fileImageProviderCache.remove(key);
  if (cached != null) {
    _fileImageProviderCache[key] = cached;
    return cached;
  }

  final provider = cacheWidth == null
      ? FileImage(File(imagePath)) as ImageProvider<Object>
      : ResizeImage.resizeIfNeeded(
          cacheWidth,
          null,
          FileImage(File(imagePath)),
        );
  _fileImageProviderCache[key] = provider;
  while (_fileImageProviderCache.length > _maxFileImageProviderEntries) {
    _fileImageProviderCache.remove(_fileImageProviderCache.keys.first);
  }
  return provider;
}
