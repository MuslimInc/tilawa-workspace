import 'dart:async';

import 'package:flutter/material.dart';

/// Short heart burst for double-tap / reaction.
class ReelHeartBurst extends StatefulWidget {
  const ReelHeartBurst({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<ReelHeartBurst> createState() => _ReelHeartBurstState();
}

class _ReelHeartBurstState extends State<ReelHeartBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.25), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    unawaited(_controller.forward().whenComplete(widget.onDone));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: const Center(
          child: Icon(Icons.favorite, size: 96, color: Colors.white),
        ),
      ),
    );
  }
}
