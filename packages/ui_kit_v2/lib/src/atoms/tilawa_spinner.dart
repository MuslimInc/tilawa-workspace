import 'package:flutter/material.dart';

/// Indeterminate circular spinner. Matches `.tw-spinner` — a 2px ring with a
/// missing arc that rotates over 800ms.
class TilawaSpinner extends StatelessWidget {
  const TilawaSpinner({
    this.size = 18,
    this.color,
    this.strokeWidth = 2,
    super.key,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(c),
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
