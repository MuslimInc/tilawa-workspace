import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Travel-style read-only search on the Home sheet lip; opens Quran index.
class HomeDashboardSearchBar extends StatelessWidget {
  const HomeDashboardSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = context.tokens;
    final TilawaHomeDashboardCardTokens cardTokens = Theme.of(
      context,
    ).componentTokens.homeDashboardCard;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String hint = context.l10n.homeSearchHint;

    return Semantics(
      button: true,
      label: hint,
      child: GestureDetector(
        onTap: () => const QuranIndexRoute().push(context),
        child: AbsorbPointer(
          child: TilawaSearchField(
            hintText: hint,
            showShadow: true,
            variant: TilawaSearchFieldVariant.catalog,
            backgroundColor: cardTokens.travelSearchFieldFill,
            borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
            margin: EdgeInsets.zero,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
