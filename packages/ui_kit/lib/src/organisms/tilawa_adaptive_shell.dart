import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/breakpoints.dart';
import '../foundation/component_tokens.dart';
import '../foundation/content_bounds.dart';
import '../foundation/design_tokens.dart';
import '../foundation/display_feature_insets.dart';
import '../foundation/safe_area_ext.dart';

/// Visible label policy for the compact bottom navigation row.
enum _CompactNavLabelStrategy {
  /// Every destination shows its label (may still ellipsis if l10n is long).
  all,

  /// Icons only; equal slot widths ([Expanded] flex 1 each).
  iconOnly,
}

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
    final bool isKeyboardOpen = context.isKeyboardVisible;

    if (windowSize == TilawaWindowSize.compact) {
      return Stack(
        children: [
          Scaffold(
            extendBody: true,
            body: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: child,
            ),
          ),
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

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final padding = context.contentSafePadding;

    return Scaffold(
      body: Stack(
        children: [
          Row(
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
                  extended: windowSize.index >= TilawaWindowSize.large.index,
                ),
              ),
              Expanded(
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: padding.copyWith(
                      left: isRtl ? padding.left : 0,
                      right: isRtl ? 0 : padding.right,
                    ),
                  ),
                  child: SafeArea(
                    left: isRtl,
                    right: !isRtl,
                    top: false,
                    bottom: false,
                    child: child,
                  ),
                ),
              ),
            ],
          ),
          Positioned.fill(child: bottomPlayer),
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
    final bottomPadding = context.floatingBottomPadding;
    final double estimatedInnerWidth =
        MediaQuery.sizeOf(context).width -
        2 * tokens.bottomNavHorizontalMargin -
        2 * tokens.bottomNavBorderWidth;
    final bool iconOnlyBar =
        estimatedInnerWidth <
        TilawaBreakpoints.compactBottomNavAllLabelsMinInnerWidth;
    final double topInset = iconOnlyBar
        ? tokens.bottomNavIconOnlyVerticalMargin
        : tokens.bottomNavVerticalMargin;

    final BorderRadius shellRadius = BorderRadius.circular(
      tokens.bottomNavRadius,
    );

    return TilawaContentBounds(
      kind: TilawaContentKind.media,
      alignment: .bottomCenter,
      child: Padding(
        padding:
            padding ??
            EdgeInsets.fromLTRB(
              tokens.bottomNavHorizontalMargin,
              topInset,
              tokens.bottomNavHorizontalMargin,
              bottomPadding,
            ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: shellRadius,
            boxShadow: tokens.bottomNavShadowOpacity > 0
                ? [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(
                        alpha: tokens.bottomNavShadowOpacity,
                      ),
                      blurRadius: tokens.bottomNavShadowBlur,
                      offset: tokens.bottomNavShadowOffset,
                    ),
                  ]
                : const [],
          ),
          child: Material(
            color: tokens.bottomNavBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: shellRadius,
              side: BorderSide(
                color: tokens.bottomNavOutlineColor,
                width: tokens.bottomNavBorderWidth,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: decoration ?? const BoxDecoration(),
              child: LayoutBuilder(
                builder: (context, innerConstraints) {
                  final strategy =
                      innerConstraints.maxWidth >=
                          TilawaBreakpoints
                              .compactBottomNavAllLabelsMinInnerWidth
                      ? _CompactNavLabelStrategy.all
                      : _CompactNavLabelStrategy.iconOnly;

                  return Row(
                    spacing: tokens.bottomNavItemGap,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (int i = 0; i < destinations.length; i++)
                        Expanded(
                          child: _NavButton(
                            destination: destinations[i],
                            isSelected: selectedIndex == i,
                            onTap: () => onDestinationSelected(i),
                            borderRadius: tokens.bottomNavInnerRadius,
                            compactLabelStrategy: strategy,
                          ),
                        ),
                    ],
                  );
                },
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
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.adaptiveShell;

    return ClipRRect(
      borderRadius: BorderRadius.circular(componentTokens.sideRailRadius),
      child: Container(
        decoration: BoxDecoration(
          color: componentTokens.sideRailBackgroundColor,
          borderRadius: BorderRadius.circular(componentTokens.sideRailRadius),
          border: Border.all(
            color: componentTokens.sideRailOutlineColor,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    extended: extended,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    backgroundColor: Colors.transparent,
                    indicatorColor: componentTokens.sideRailIndicatorColor,
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
              ),
            );
          },
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
    required this.compactLabelStrategy,
  });

  final TilawaNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;
  final double borderRadius;
  final _CompactNavLabelStrategy compactLabelStrategy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.adaptiveShell;
    final selectedFg = theme.colorScheme.primary;
    final unselectedFg = theme.colorScheme.onSurfaceVariant;
    final Color iconColor = isSelected ? selectedFg : unselectedFg;

    final Widget iconWidget = destination.iconBuilder != null
        ? destination.iconBuilder!(
            context,
            isSelected: isSelected,
            color: iconColor,
          )
        : Icon(
            isSelected
                ? (destination.activeIcon ?? destination.icon)
                : destination.icon,
            key: ValueKey('${destination.icon.hashCode}_$isSelected'),
            size: tokens.navButtonIconSize,
            color: iconColor,
          );

    final BorderRadius effectiveBorderRadius = BorderRadius.circular(
      borderRadius,
    );

    final bool showVisibleLabel = switch (compactLabelStrategy) {
      _CompactNavLabelStrategy.all => true,
      _CompactNavLabelStrategy.iconOnly => false,
    };

    final Widget column = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: isSelected
              ? tokens.navButtonSelectedCenterScale
              : tokens.navButtonUnselectedScale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: PageTransitionSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation, secondaryAnimation) =>
                FadeThroughTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  fillColor: Colors.transparent,
                  child: child,
                ),
            child: KeyedSubtree(key: ValueKey(isSelected), child: iconWidget),
          ),
        ),
        if (showVisibleLabel) ...[
          SizedBox(height: tokens.navButtonGap),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
              fontSize: tokens.navButtonLabelFontSize,
              fontWeight: isSelected
                  ? tokens.navButtonSelectedLabelWeight
                  : tokens.navButtonUnselectedLabelWeight,
              color: isSelected ? selectedFg : unselectedFg,
              height: 1.15,
            ),
            child: Text(
              destination.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );

    final bool iconOnly =
        compactLabelStrategy == _CompactNavLabelStrategy.iconOnly;
    final double slotMinHeight = iconOnly
        ? tokens.navButtonIconOnlyMinHeight
        : tokens.navButtonMinHeight;
    final double outerVerticalPadding = iconOnly
        ? tokens.navButtonIconOnlyVerticalPadding
        : tokens.navButtonVerticalPadding;
    final double pillVerticalPadding = iconOnly
        ? tokens.navButtonIconOnlySelectionContainerVerticalPadding
        : tokens.navButtonSelectionContainerVerticalPadding;

    // Full-cell tap target; selected tab gets a soft primary-tint pill
    // ([navButtonSelectedBackgroundColor]) for clearer wayfinding.
    final Widget button = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: effectiveBorderRadius,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: slotMinHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: outerVerticalPadding,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxPillWidth = constraints.maxWidth * 0.86;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxPillWidth),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: pillVerticalPadding,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tokens.navButtonSelectedBackgroundColor
                            : Colors.transparent,
                        borderRadius: effectiveBorderRadius,
                      ),
                      child: column,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      identifier: destination.identifier,
      child: ExcludeSemantics(child: button),
    );
  }
}
