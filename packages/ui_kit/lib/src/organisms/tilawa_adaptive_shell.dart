import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/breakpoints.dart';
import '../foundation/content_bounds.dart';
import '../foundation/design_tokens.dart';
import '../foundation/display_feature_insets.dart';

/// Builds the icon widget for a nav destination. Receives selection state and
/// the resolved tint the shell would apply to a material [Icon]; callers may
/// honor or ignore the color as they see fit (e.g. multi-color SVGs).
typedef TilawaNavIconBuilder =
    Widget Function(
      BuildContext context, {
      required bool isSelected,
      required Color color,
    });

/// A destination for the adaptive shell.
///
/// Provide [iconBuilder] to render non-Material glyphs (SVG, Lottie, custom
/// painters). The shell itself has no rendering dependencies — the caller
/// owns the icon pipeline.
class TilawaNavDestination {
  const TilawaNavDestination({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.iconBuilder,
  });

  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final TilawaNavIconBuilder? iconBuilder;
}

/// A shell that adapts its navigation based on the window size.
///
/// - Compact: Shows a bottom navigation bar.
/// - Medium/Expanded: Shows a side navigation rail.
///
/// This shell also respects [DisplayFeature]s (hinges/folds) on foldable
/// devices, ensuring navigation elements don't overlap fold regions.
class TilawaAdaptiveShell extends StatelessWidget {
  const TilawaAdaptiveShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    required this.bottomPlayer,
    this.bottomBarPadding,
    this.bottomBarDecoration,
    this.avoidDisplayFeatures = true,
  });

  final List<TilawaNavDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  /// The bottom player (or similar floating control) that should respect
  /// the navigation bar/rail boundaries.
  final Widget bottomPlayer;

  /// Optional padding for the bottom bar in compact mode.
  final EdgeInsetsGeometry? bottomBarPadding;

  /// Optional decoration for the bottom bar in compact mode.
  final Decoration? bottomBarDecoration;

  /// Whether to avoid placing content under display features (hinges/folds).
  /// Defaults to true. Set to false to disable foldable-aware padding.
  final bool avoidDisplayFeatures;

  @override
  Widget build(BuildContext context) {
    final windowSize = context.windowSize;
    final displayIndex = (selectedIndex == -1) ? null : selectedIndex;

    if (windowSize == TilawaWindowSize.compact) {
      return Scaffold(
        extendBody: true,
        body: Stack(children: [child, bottomPlayer]),
        bottomNavigationBar: _BottomNavBar(
          destinations: destinations,
          selectedIndex: displayIndex,
          onDestinationSelected: onDestinationSelected,
          padding: bottomBarPadding,
          decoration: bottomBarDecoration,
        ),
      );
    }

    final hingePadding = avoidDisplayFeatures
        ? context.getHingeAvoidancePadding(AxisDirection.left)
        : EdgeInsetsDirectional.zero;

    return Scaffold(
      body: Row(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: hingePadding.start,
              end: hingePadding.end,
            ),
            child: _SideNavRail(
              destinations: destinations,
              selectedIndex: displayIndex,
              onDestinationSelected: onDestinationSelected,
              extended: windowSize == TilawaWindowSize.expanded,
            ),
          ),
          Expanded(child: Stack(children: [child, bottomPlayer])),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.padding,
    this.decoration,
  });

  // Capsule radius for the floating bottom bar. Larger than any stock token,
  // so declared locally with a clear name rather than a magic literal.
  static const double _capsuleRadius = 32.0;

  final List<TilawaNavDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final EdgeInsetsGeometry? padding;
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    final double horizontalMargin = tokens.spaceLarge;
    final double verticalMargin = tokens.spaceMedium;
    final double internalPadding = tokens.spaceSmall;
    // Nested-radius rule: inner capsule follows the outer edge inset by the
    // vertical padding so the rounding stays concentric.
    final double innerRadius = _capsuleRadius - internalPadding;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return TilawaContentBounds(
      kind: TilawaContentKind.media,
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding:
            padding ??
            EdgeInsets.fromLTRB(
              horizontalMargin,
              verticalMargin,
              horizontalMargin,
              bottomPadding + verticalMargin,
            ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_capsuleRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: tokens.blurGlass,
              sigmaY: tokens.blurGlass,
            ),
            child: DecoratedBox(
              decoration:
                  decoration ??
                  BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(_capsuleRadius),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ),
              child: Row(
                spacing: tokens.spaceExtraSmall,
                children: [
                  for (int i = 0; i < destinations.length; i++)
                    Expanded(
                      child: _NavButton(
                        destination: destinations[i],
                        isSelected: selectedIndex == i,
                        onTap: () => onDestinationSelected(i),
                        borderRadius: innerRadius,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SideNavRail extends StatelessWidget {
  const _SideNavRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.extended,
  });

  final List<TilawaNavDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveColor = theme.colorScheme.onSurfaceVariant;
    final activeColor = theme.colorScheme.onPrimaryContainer;

    return NavigationRail(
      extended: extended,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: theme.colorScheme.surface,
      indicatorColor: theme.colorScheme.primaryContainer,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      destinations: [
        for (final d in destinations)
          NavigationRailDestination(
            icon: d.iconBuilder != null
                ? d.iconBuilder!(
                    context,
                    isSelected: false,
                    color: inactiveColor,
                  )
                : Icon(d.icon),
            selectedIcon: d.iconBuilder != null
                ? d.iconBuilder!(context, isSelected: true, color: activeColor)
                : Icon(d.activeIcon ?? d.icon),
            label: Text(d.label),
          ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.destination,
    required this.isSelected,
    required this.onTap,
    required this.borderRadius,
  });

  final TilawaNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurfaceVariant;
    final tint = isSelected ? activeColor : inactiveColor;
    final baseLabelStyle = theme.textTheme.labelSmall ?? const TextStyle();

    final Widget iconWidget = destination.iconBuilder != null
        ? destination.iconBuilder!(context, isSelected: isSelected, color: tint)
        : Icon(
            isSelected
                ? (destination.activeIcon ?? destination.icon)
                : destination.icon,
            key: ValueKey('${destination.icon.hashCode}_$isSelected'),
            size: 22,
            color: tint,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(borderRadius),
        child: AnimatedContainer(
          duration: tokens.durationFast,
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 64),
          padding: EdgeInsets.symmetric(vertical: tokens.spaceExtraSmall),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: tokens.spaceExtraSmall,
            children: [
              AnimatedScale(
                duration: tokens.durationFast,
                scale: isSelected ? 1 : 0.95,
                child: AnimatedSwitcher(
                  duration: tokens.durationFast,
                  child: iconWidget,
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: tokens.durationFast,
                style: baseLabelStyle.copyWith(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: tint,
                ),
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
