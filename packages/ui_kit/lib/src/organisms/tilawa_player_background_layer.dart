import 'dart:ui';

import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

class TilawaPlayerBackgroundLayer extends StatelessWidget {
  const TilawaPlayerBackgroundLayer({
    super.key,
    required this.image,
    this.blurAmount,
    this.overlayOpacity,
    this.overlayColor,
    this.fit = .cover,
  });

  final ImageProvider<Object>? image;
  final double? blurAmount;
  final double? overlayOpacity;
  final Color? overlayColor;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).componentTokens.playerBackground;
    final effectiveImage = image;

    if (effectiveImage == null) {
      return const SizedBox.shrink();
    }

    final mediaSize = MediaQuery.sizeOf(context);
    final cacheWidth = (mediaSize.width * tokens.cacheWidthScale).round();
    final effectiveBlurAmount = blurAmount ?? tokens.defaultBlurAmount;
    final effectiveOverlayOpacity =
        overlayOpacity ?? tokens.defaultOverlayOpacity;

    return Stack(
      fit: .expand,
      children: [
        Image(
          image: ResizeImage.resizeIfNeeded(cacheWidth, null, effectiveImage),
          fit: fit,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
        if (effectiveBlurAmount > 0)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: effectiveBlurAmount,
                sigmaY: effectiveBlurAmount,
              ),
              child: const SizedBox.shrink(),
            ),
          ),
        Positioned.fill(
          child: ColoredBox(
            color: (overlayColor ?? tokens.overlayColor).withValues(
              alpha: effectiveOverlayOpacity,
            ),
          ),
        ),
      ],
    );
  }
}
