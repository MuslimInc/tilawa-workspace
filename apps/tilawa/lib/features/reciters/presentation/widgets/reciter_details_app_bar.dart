import 'package:flutter/material.dart';
import 'package:tilawa/shared/widgets/tilawa_back_button.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Dense app bar showing the reciter name on a single solid primary
/// surface. Decorative circles and gradient fills were intentionally
/// removed in the visual-simplification pass — the goal is to let the
/// reciter name be the focal element, not the chrome.
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
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: TilawaBackButton(color: appBarForegroundColor),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: appBarForegroundColor.withValues(alpha: 0.18),
            child: Text(
              reciter.name[0],
              style: theme.textTheme.labelLarge?.copyWith(
                color: appBarForegroundColor,
                fontWeight: FontWeight.w700,
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
                    fontWeight: FontWeight.w700,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
