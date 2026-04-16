import 'package:flutter/material.dart';

/// Renders a single line of Quran text.
class QuranLineImage extends StatelessWidget {
  const QuranLineImage({super.key, required this.provider});

  final ImageProvider<Object>? provider;

  @override
  Widget build(BuildContext context) {
    final imageProvider = provider;
    if (imageProvider == null) {
      return const SizedBox.shrink();
    }

    return Image(
      image: imageProvider,
      fit: BoxFit.fill,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
