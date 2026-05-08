import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

/// Compact app bar showing the reciter name with a gradient
/// background and subtle decorative elements.
class ReciterDetailsAppBar extends StatelessWidget {
  const ReciterDetailsAppBar({super.key, required this.reciter});

  final ReciterEntity reciter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final Color appBarForegroundColor = colorScheme.onPrimary;

    return SliverAppBar(
      pinned: true,
      backgroundColor: colorScheme.primary,
      foregroundColor: appBarForegroundColor,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: appBarForegroundColor),
        onPressed: () => context.pop(),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary, colorScheme.secondary],
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
            backgroundColor: appBarForegroundColor.withValues(alpha: 0.2),
            child: Text(
              reciter.name[0],
              style: theme.textTheme.labelLarge?.copyWith(
                color: appBarForegroundColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: tokens.spaceSmall + tokens.spaceTiny),
          Flexible(
            child: Text(
              reciter.name,
              style: context
                  .responsiveStyle((t) => t.titleLarge)
                  ?.copyWith(
                    color: appBarForegroundColor,
                    fontWeight: FontWeight.bold,
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
        color: Theme.of(
          context,
        ).colorScheme.onPrimary.withValues(alpha: opacity),
      ),
    );
  }
}
