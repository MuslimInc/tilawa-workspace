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
    final MeMuslimDesignTokens tokens = theme.tokens;
    final TilawaHomeDashboardCardTokens cardTokens =
        theme.componentTokens.homeDashboardCard;

    return TilawaButton(
      text: label,
      variant: TilawaButtonVariant.ghost,
      shrinkWrapTapTarget: true,
      foregroundColor: cardTokens.travelSectionLinkColor,
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
      textStyle: theme.textTheme.labelLarge?.copyWith(
        color: cardTokens.travelSectionLinkColor,
        fontWeight: FontWeight.w600,
      ),
      onPressed: onPressed,
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
