import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Travel-style tertiary action on section headers (See all / View all).
class HomeSectionLink extends StatelessWidget {
  const HomeSectionLink({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final TilawaHomeDashboardCardTokens cardTokens =
        theme.componentTokens.homeDashboardCard;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: cardTokens.travelSectionLinkColor,
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
        minimumSize: Size(
          tokens.minInteractiveDimension,
          tokens.minInteractiveDimension,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: cardTokens.travelSectionLinkColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Default localized "See all" link for Home sections.
class HomeSeeAllLink extends StatelessWidget {
  const HomeSeeAllLink({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return HomeSectionLink(
      label: context.l10n.seeAll,
      onPressed: onPressed,
    );
  }
}
