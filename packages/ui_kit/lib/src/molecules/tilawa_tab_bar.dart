import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

/// Visual style for [TilawaTabBar].
enum TilawaTabBarVariant {
  /// Underline indicator — app bars and pinned section headers. Styling comes
  /// from [ThemeData.tabBarTheme] (Flex `forAppBar` in [AppTheme]).
  underline,

  /// Pill indicator inside a rounded track. Uses [TilawaChipTokens] catalog
  /// selection colors. Prefer [underline] for screen-level section tabs.
  pill,
}

/// Design-system tab switcher backed by [TabController].
///
/// Prefer [TilawaTabBarVariant.underline] for screen-level section tabs.
/// Prefer [TilawaSegmentedControl] for compact binary/ternary switches that do
/// not need a [TabBarView] (no controller required).
class TilawaTabBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a tab bar.
  const TilawaTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.variant = TilawaTabBarVariant.underline,
    this.onTap,
    this.tabAlignment = TabAlignment.fill,
    this.dividerHeight = 0,
  });

  final TabController controller;
  final List<Widget> tabs;
  final TilawaTabBarVariant variant;
  final ValueChanged<int>? onTap;

  /// Defaults to [TabAlignment.fill] for two-up section tabs.
  final TabAlignment tabAlignment;

  /// Divider under the tab row. Defaults to `0` for pinned in-scroll headers.
  final double dividerHeight;

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    final tabBar = _buildTabBar(context);

    if (variant != TilawaTabBarVariant.pill) {
      return tabBar;
    }

    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final scheme = theme.colorScheme;
    final trackRadius = _TilawaTabBarInteraction.trackRadius(tokens);

    return SizedBox(
      height: kTextTabBarHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(trackRadius),
        ),
        child: tabBar,
      ),
    );
  }

  TabBar _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final scheme = theme.colorScheme;
    final interaction = _TilawaTabBarInteraction.resolve(
      tokens: tokens,
      scheme: scheme,
      variant: variant,
    );

    if (variant == TilawaTabBarVariant.pill) {
      final chip = theme.componentTokens.chip;

      return TabBar(
        controller: controller,
        onTap: onTap,
        splashBorderRadius: interaction.splashBorderRadius,
        overlayColor: interaction.overlayColor,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.all(tokens.spaceExtraSmall),
        indicator: BoxDecoration(
          color: chip.catalogSelectedBackgroundColor,
          borderRadius: interaction.splashBorderRadius,
        ),
        labelColor: chip.catalogSelectedForegroundColor,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: chip.selectionFontWeight,
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        tabs: tabs,
      );
    }

    return TabBar(
      controller: controller,
      onTap: onTap,
      tabAlignment: tabAlignment,
      dividerHeight: dividerHeight,
      splashBorderRadius: interaction.splashBorderRadius,
      overlayColor: interaction.overlayColor,
      tabs: tabs,
    );
  }
}

@immutable
class _TilawaTabBarInteraction {
  const _TilawaTabBarInteraction({
    required this.splashBorderRadius,
    required this.overlayColor,
  });

  final BorderRadius splashBorderRadius;
  final WidgetStateProperty<Color?> overlayColor;

  static _TilawaTabBarInteraction resolve({
    required MeMuslimDesignTokens tokens,
    required ColorScheme scheme,
    required TilawaTabBarVariant variant,
  }) {
    return _TilawaTabBarInteraction(
      splashBorderRadius: BorderRadius.circular(
        _splashRadius(tokens, variant: variant),
      ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return scheme.primary.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return scheme.onSurface.withValues(alpha: 0.04);
        }
        return null;
      }),
    );
  }

  static double trackRadius(MeMuslimDesignTokens tokens) {
    return tokens.resolveRadius(family: TilawaRadiusFamily.chrome);
  }

  static double _splashRadius(
    MeMuslimDesignTokens tokens, {
    required TilawaTabBarVariant variant,
  }) {
    if (variant == TilawaTabBarVariant.pill) {
      return tokens.concentricInner(
        outerRadius: trackRadius(tokens),
        padding: tokens.spaceExtraSmall,
      );
    }

    return tokens.resolveRadius(family: TilawaRadiusFamily.section);
  }
}
