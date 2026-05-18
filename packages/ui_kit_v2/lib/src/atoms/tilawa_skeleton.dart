import 'package:flutter/material.dart';

/// Shimmering skeleton block. Use to placehold rows during data load.
/// Mirrors `.tw-skeleton`.
class TilawaSkeleton extends StatefulWidget {
  const TilawaSkeleton({
    this.width,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    super.key,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<TilawaSkeleton> createState() => _TilawaSkeletonState();
}

class _TilawaSkeletonState extends State<TilawaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        final t = _ctl.value;
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              gradient: LinearGradient(
                begin: Alignment(-1 + 4 * t, 0),
                end: Alignment(1 + 4 * t, 0),
                colors: const [
                  Color(0x0F0F172A),
                  Color(0x1A0F172A),
                  Color(0x0F0F172A),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
