import 'package:flutter/material.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

/// Compact app bar showing the reciter name with a gradient
/// background and subtle decorative elements.
class ReciterDetailsAppBar extends StatelessWidget {
  const ReciterDetailsAppBar({super.key, required this.reciter});

  final ReciterEntity reciter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      backgroundColor: theme.primaryColor,
      leading: const BackButton(color: Colors.white),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.primaryColor, theme.colorScheme.secondary],
            ),
          ),
          child: Stack(
            children: [
              // Subtle decorative circles
              Positioned(
                left: -30,
                top: -20,
                child: _DecorativeCircle(size: 80, opacity: 0.06),
              ),
              Positioned(
                right: -15,
                bottom: -10,
                child: _DecorativeCircle(size: 60, opacity: 0.04),
              ),
            ],
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Small inline avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              reciter.name[0],
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              reciter.name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
