import 'package:flutter/material.dart';

/// Which edge of the clipped rectangle receives the scalloped wave.
enum TilawaWaveEdge {
  top,
  bottom,
}

/// Scalloped wave clipper for hero-to-sheet transitions on Home and hubs.
///
/// Uses repeating quadratic curves — Talabat-style polish without brand colors.
class TilawaWaveClipper extends CustomClipper<Path> {
  const TilawaWaveClipper({
    required this.amplitude,
    this.wavelength = 56,
    this.edge = TilawaWaveEdge.top,
  });

  final double amplitude;
  final double wavelength;
  final TilawaWaveEdge edge;

  @override
  Path getClip(Size size) {
    if (edge == TilawaWaveEdge.top) {
      return _clipTopWave(size);
    }
    return _clipBottomWave(size);
  }

  Path _clipTopWave(Size size) {
    final Path path = Path()..moveTo(0, amplitude);
    final double waveWidth = wavelength.clamp(24, size.width);
    final int waveCount = (size.width / waveWidth).ceil().clamp(1, 32);

    for (int index = 0; index < waveCount; index++) {
      final double startX = index * waveWidth;
      final double endX = (index + 1) * waveWidth;
      path.quadraticBezierTo(
        startX + waveWidth * 0.5,
        0,
        endX,
        amplitude,
      );
    }

    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  Path _clipBottomWave(Size size) {
    final Path path = Path()..moveTo(0, 0);
    final double waveWidth = wavelength.clamp(24, size.width);
    final int waveCount = (size.width / waveWidth).ceil().clamp(1, 32);
    final double baseline = size.height - amplitude;

    path
      ..lineTo(size.width, 0)
      ..lineTo(size.width, baseline);

    for (int index = waveCount - 1; index >= 0; index--) {
      final double endX = index * waveWidth;
      path.quadraticBezierTo(
        endX + waveWidth * 0.5,
        size.height,
        endX,
        baseline,
      );
    }

    path
      ..lineTo(0, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant TilawaWaveClipper oldClipper) {
    return oldClipper.amplitude != amplitude ||
        oldClipper.wavelength != wavelength ||
        oldClipper.edge != edge;
  }
}
