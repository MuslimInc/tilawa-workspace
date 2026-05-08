import 'package:flutter/material.dart';

/// Renders a single line of Quran text.
class QuranLineImage extends StatelessWidget {
  const QuranLineImage({super.key, required this.provider, this.colorFilter});

  final ImageProvider<Object>? provider;
  final ColorFilter? colorFilter;

  @override
  Widget build(BuildContext context) {
    final imageProvider = provider;
    if (imageProvider == null) {
      return const SizedBox.shrink();
    }

    final image = Image(
      image: imageProvider,
      fit: BoxFit.fill,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );

    if (colorFilter != null) {
      return ColorFiltered(colorFilter: colorFilter!, child: image);
    }

    return image;
  }
}
