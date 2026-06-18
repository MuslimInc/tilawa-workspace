import 'package:flutter/material.dart';

/// Asset paths for the stylized Kaaba illustrations (Behance reference).
abstract final class KaabaAssets {
  static const String marker = 'assets/icons/kaaba_marker.png';

  /// Compass dial marker (north / Qibla target).
  static const double compassSize = 20;

  /// Decorative size on the surah reader gold header.
  static const double surahHeaderSize = 44;
}

/// Vector Kaaba marker used on the Qibla compass and surah header decor.
class KaabaIcon extends StatelessWidget {
  const KaabaIcon({
    super.key,
    required this.size,
    this.semanticLabel,
    this.opacity,
  });

  final double size;
  final String? semanticLabel;
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    final Widget icon = Image.asset(
      KaabaAssets.marker,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    final Widget child = opacity == null
        ? icon
        : Opacity(opacity: opacity!, child: icon);

    if (semanticLabel == null) {
      return child;
    }

    return Semantics(
      label: semanticLabel,
      image: true,
      child: child,
    );
  }
}
