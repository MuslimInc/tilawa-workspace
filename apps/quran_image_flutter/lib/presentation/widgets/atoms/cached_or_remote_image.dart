import 'package:flutter/material.dart';
import 'package:quran_image_flutter/core/utils/quran_image_utils.dart';

/// Renders an image from a local file path if available, falling back to a URL.
class CachedOrRemoteImage extends StatelessWidget {
  const CachedOrRemoteImage({
    super.key,
    required this.localPath,
    required this.remoteUrl,
    required this.fit,
    required this.gaplessPlayback,
    this.cacheWidth,
  });

  final String? localPath;
  final String remoteUrl;
  final BoxFit fit;
  final bool gaplessPlayback;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final path = localPath;
    if (path != null) {
      return Image(
        image: cachedFileImageProvider(imagePath: path, cacheWidth: cacheWidth),
        fit: fit,
        gaplessPlayback: gaplessPlayback,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    return Image.network(
      remoteUrl,
      fit: fit,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
