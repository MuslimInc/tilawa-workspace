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
      return Stack(
        children: [
          Scaffold(extendBody: true, body: child),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomNavBar(
              destinations: destinations,
              selectedIndex: displayIndex,
              onDestinationSelected: onDestinationSelected,
              padding: bottomBarPadding,
              decoration: bottomBarDecoration,
            ),
          ),
          Positioned.fill(child: bottomPlayer),
        ],
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
          Expanded(
            child: Stack(
              children: [
                child,
                Positioned.fill(child: bottomPlayer),
              ],
            ),
          ),
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
    final double capsuleRadius = tokens.radiusExtraLarge + tokens.spaceSmall;
    // Nested-radius rule: inner capsule follows the outer edge inset by the
    // vertical padding so the rounding stays concentric.
    final double innerRadius = capsuleRadius - internalPadding;
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
          borderRadius: BorderRadius.circular(capsuleRadius),
          child: DecoratedBox(
            decoration:
                decoration ??
                BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(capsuleRadius),
                  border: Border.all(
                    color: theme.colorScheme.onPrimary,
                    width: tokens.borderWidthThin * 2,
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
                      isCenterItem: i == destinations.length ~/ 2,
                      onTap: () => onDestinationSelected(i),
                      borderRadius: innerRadius,
                    ),
                  ),
              ],
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
    final tokens = theme.tokens;

    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusLarge),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(
            alpha: tokens.opacityGlass,
          ),
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: tokens.opacitySubtle,
            ),
            width: tokens.borderWidthThin,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(
                alpha: tokens.opacitySubtle / 2,
              ),
              blurRadius: tokens.blurGlass,
              offset: Offset(tokens.spaceTiny, 0),
            ),
          ],
        ),
        child: NavigationRail(
          extended: extended,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          backgroundColor: Colors.transparent,
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
                    ? d.iconBuilder!(
                        context,
                        isSelected: true,
                        color: activeColor,
                      )
                    : Icon(d.activeIcon ?? d.icon),
                label: Text(d.label),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.destination,
    required this.isSelected,
    required this.isCenterItem,
    required this.onTap,
    required this.borderRadius,
  });

  final TilawaNavDestination destination;
  final bool isSelected;
  final bool isCenterItem;
  final VoidCallback onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final onPrimaryColor = theme.colorScheme.onPrimary;

    // High contrast: selected items inverted (onPrimary bg with primary text)
    final backgroundColor = isSelected ? onPrimaryColor : Colors.transparent;

    final baseLabelStyle = theme.textTheme.labelSmall ?? const TextStyle();

    final Widget iconWidget = destination.iconBuilder != null
        ? destination.iconBuilder!(
            context,
            isSelected: isSelected,
            color: onPrimaryColor,
          )
        : Icon(
            isSelected
                ? (destination.activeIcon ?? destination.icon)
                : destination.icon,
            key: ValueKey('${destination.icon.hashCode}_$isSelected'),
            size: tokens.iconSizeMedium + tokens.spaceTiny,
            color: onPrimaryColor,
          );

    final double iconScale = isCenterItem
        ? (isSelected ? 1 + tokens.opacitySubtle : 1.0)
        : (isSelected ? 1.0 : 1 - tokens.opacitySubtle / 2);

    final double backgroundAlpha = isSelected
        ? tokens.opacityMedium -
              tokens.opacitySubtle +
              (isCenterItem ? tokens.opacitySubtle / 2 : 0)
        : 0.0;
    final double labelFontSize = tokens.iconSizeExtraSmall - tokens.spaceTiny;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          constraints: BoxConstraints(
            minHeight: tokens.iconSizeExtraLarge + tokens.spaceLarge,
          ),
          padding: EdgeInsets.symmetric(vertical: tokens.spaceExtraSmall),
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: backgroundAlpha),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: tokens.spaceExtraSmall,
            children: [
              Transform.scale(scale: iconScale, child: iconWidget),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: baseLabelStyle.copyWith(
                  fontSize: labelFontSize,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: onPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
