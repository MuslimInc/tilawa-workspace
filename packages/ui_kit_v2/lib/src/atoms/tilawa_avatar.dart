import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

enum TilawaAvatarSize {
  md, // 44px
  lg, // 56px
  xl, // 80px (ProfileHero)
}

/// Circular avatar with the brand emerald gradient and a faint gold ring.
/// Use [initials] to seed a monogram when an image isn't available.
class TilawaAvatar extends StatelessWidget {
  const TilawaAvatar({
    required this.initials,
    this.image,
    this.size = TilawaAvatarSize.md,
    this.showGoldRing = true,
    super.key,
  });

  final String initials;
  final ImageProvider<Object>? image;
  final TilawaAvatarSize size;
  final bool showGoldRing;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final (dim, fontSize, ringSize) = switch (size) {
      TilawaAvatarSize.md => (44.0, 14.0, 1.5),
      TilawaAvatarSize.lg => (56.0, 16.0, 1.5),
      TilawaAvatarSize.xl => (80.0, 28.0, 2.0),
    };

    final ringInset = size == TilawaAvatarSize.xl ? 5.0 : 3.0;

    final base = Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TilawaPalette.green500, TilawaPalette.green600],
        ),
        shape: BoxShape.circle,
        boxShadow: size == TilawaAvatarSize.xl ? TilawaShadows.el2 : null,
        image: image == null
            ? null
            : DecorationImage(image: image!, fit: BoxFit.cover),
      ),
      child: image != null
          ? null
          : Center(
              child: Text(
                initials.toUpperCase(),
                style: TextStyle(
                  fontFamily: TilawaFontFamily.ui,
                  fontWeight: FontWeight.w600,
                  color: theme.tokens.colors.fgOnPrimary,
                  fontSize: fontSize,
                  letterSpacing: 0.28,
                ),
              ),
            ),
    );

    if (!showGoldRing) return base;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        base,
        Positioned(
          left: -ringInset,
          top: -ringInset,
          right: -ringInset,
          bottom: -ringInset,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: TilawaPalette.gold500.withValues(
                    alpha: size == TilawaAvatarSize.xl ? 0.4 : 0.25,
                  ),
                  width: ringSize,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
