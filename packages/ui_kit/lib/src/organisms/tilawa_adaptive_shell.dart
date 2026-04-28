import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/breakpoints.dart';
import '../foundation/component_tokens.dart';
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
    this.identifier,
  });

  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final TilawaNavIconBuilder? iconBuilder;

  /// Optional [Semantics.identifier] exposed to accessibility tools such as
  /// Maestro. Prefer this over Flutter Keys for E2E test targeting.
  final String? identifier;
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
    final bool isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    if (windowSize == TilawaWindowSize.compact) {
      return Stack(
        children: [
          Scaffold(extendBody: true, body: child),
          if (!isKeyboardOpen)
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
        ? context.getHingeAvoidancePadding(.left)
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
    final tokens = theme.componentTokens.adaptiveShell;
    final designTokens = theme.tokens;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return TilawaContentBounds(
      kind: TilawaContentKind.media,
      alignment: .bottomCenter,
      child: Padding(
        padding:
            padding ??
            EdgeInsets.fromLTRB(
              tokens.bottomNavHorizontalMargin,
              tokens.bottomNavVerticalMargin,
              tokens.bottomNavHorizontalMargin,
              bottomPadding,
            ),
        child: Material(
          color: theme.colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.bottomNavRadius),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(
                alpha: designTokens.opacitySubtle,
              ),
              width: tokens.bottomNavBorderWidth,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: decoration ?? const BoxDecoration(),
            child: Row(
              spacing: tokens.bottomNavItemGap,
              children: [
                for (int i = 0; i < destinations.length; i++)
                  Expanded(
                    child: _NavButton(
                      destination: destinations[i],
                      isSelected: selectedIndex == i,
                      onTap: () => onDestinationSelected(i),
                      borderRadius: tokens.bottomNavInnerRadius,
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
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.adaptiveShell;

    return ClipRRect(
      borderRadius: BorderRadius.circular(componentTokens.sideRailRadius),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(
            alpha: designTokens.opacityGlass,
          ),
          borderRadius: BorderRadius.circular(componentTokens.sideRailRadius),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: designTokens.opacitySubtle,
            ),
            width: designTokens.borderWidthThin,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(
                alpha: componentTokens.sideRailShadowOpacity,
              ),
              blurRadius: componentTokens.sideRailShadowBlur,
              offset: componentTokens.sideRailShadowOffset,
            ),
          ],
        ),
        child: NavigationRail(
          extended: extended,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          backgroundColor: Colors.transparent,
          indicatorColor: theme.colorScheme.primaryContainer,
          labelType: extended ? .none : .all,
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
    final tokens = theme.componentTokens.adaptiveShell;
    final selectedBg = theme.colorScheme.primaryContainer;
    final selectedFg = theme.colorScheme.onPrimaryContainer;
    final unselectedFg = theme.colorScheme.onSurfaceVariant;

    final baseLabelStyle = theme.textTheme.labelSmall ?? const TextStyle();

    final Widget iconWidget = destination.iconBuilder != null
        ? destination.iconBuilder!(
            context,
            isSelected: isSelected,
            color: isSelected ? selectedFg : unselectedFg,
          )
        : Icon(
            isSelected
                ? (destination.activeIcon ?? destination.icon)
                : destination.icon,
            key: ValueKey('${destination.icon.hashCode}_$isSelected'),
            size: tokens.navButtonIconSize,
            color: isSelected ? selectedFg : unselectedFg,
          );

    final Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          constraints: BoxConstraints(minHeight: tokens.navButtonMinHeight),
          padding: EdgeInsets.symmetric(
            vertical: tokens.navButtonVerticalPadding,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Column(
            mainAxisSize: .min,
            mainAxisAlignment: .center,
            spacing: tokens.navButtonGap,
            children: [
              iconWidget,
              Text(
                destination.label,
                maxLines: 2,
                overflow: .ellipsis,
                textAlign: .center,
                style: baseLabelStyle.copyWith(
                  fontSize: tokens.navButtonLabelFontSize,
                  fontWeight: isSelected
                      ? tokens.navButtonSelectedLabelWeight
                      : tokens.navButtonUnselectedLabelWeight,
                  color: isSelected ? selectedFg : unselectedFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (destination.identifier case final String id) {
      return Semantics(identifier: id, child: button);
    }
    return button;
  }
}
