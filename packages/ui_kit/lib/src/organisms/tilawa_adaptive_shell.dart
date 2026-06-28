import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/app_colors.dart';
import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/tilawa_interactive_surface.dart';

/// [ValueListenable] that is always `true` and never notifies.
///
/// Used as the default for [TilawaAdaptiveShell.phoneBottomNavigationBarVisible]
/// so the shell does not need a long-lived [ValueNotifier].
class _AlwaysShowPhoneBottomNavListenable implements ValueListenable<bool> {
  const _AlwaysShowPhoneBottomNavListenable();

  @override
  bool get value => true;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

const _kAlwaysShowPhoneBottomNav = _AlwaysShowPhoneBottomNavListenable();

/// Direction for horizontal swipe gestures on the phone bottom nav bar.
enum TilawaNavAdjacentDirection {
  /// Move to the previous destination in bar order.
  previous,

  /// Move to the next destination in bar order.
  next,
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
    this.selectionUsesBackground = true,
  });

  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final TilawaNavIconBuilder? iconBuilder;

  /// Optional [Semantics.identifier] exposed to accessibility tools such as
  /// Maestro. Prefer this over Flutter Keys for E2E test targeting.
  final String? identifier;

  /// When false, the selected tab uses only [iconBuilder] chrome (e.g. profile
  /// photo with a ring) instead of the neutral pill fill.
  final bool selectionUsesBackground;
}

/// A shell with a shared bottom navigation bar on every window size.
///
/// One [Scaffold] hosts tab [child] and a shared [Scaffold.bottomNavigationBar]
/// (not a nested bar per tab). Phone bottom nav is **icon-only**; destination
/// [TilawaNavDestination.label] values are exposed through semantics. Optional
/// [phoneBottomNavigationBarVisible] can hide the bar (e.g. full-screen player).
///
/// Respects [DisplayFeature]s (hinges/folds) on foldable devices.
class TilawaAdaptiveShell extends StatelessWidget {
  const TilawaAdaptiveShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    required this.bottomPlayer,
    this.onAdjacentDestinationSelected,
    this.phoneFooterAboveNav,
    this.phoneBottomNavigationBarVisible,
    this.avoidDisplayFeatures = true,
  });

  final List<TilawaNavDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<TilawaNavAdjacentDirection>? onAdjacentDestinationSelected;
  final Widget child;

  /// The bottom player (or similar floating control) that should respect
  /// the navigation bar/rail boundaries.
  final Widget bottomPlayer;

  /// Optional chrome laid out directly above the phone [BottomNavigationBar]
  /// (e.g. a mini media player). Rendered below the scrolling body, not as a
  /// full-screen overlay on top of it.
  final Widget? phoneFooterAboveNav;

  /// When non-null, narrow (phone) window class shows the bottom bar only
  /// while this value is
  /// true (e.g. hide while a full-screen sheet covers the tab bar).
  final ValueListenable<bool>? phoneBottomNavigationBarVisible;

  /// Whether to avoid placing content under display features (hinges/folds).
  /// Defaults to true. Set to false to disable foldable-aware padding.
  final bool avoidDisplayFeatures;

  @override
  Widget build(BuildContext context) {
    final int? displayIndex = (selectedIndex == -1) ? null : selectedIndex;
    final ValueListenable<bool> phoneNavListenable =
        phoneBottomNavigationBarVisible ?? _kAlwaysShowPhoneBottomNav;

    return ValueListenableBuilder<bool>(
      valueListenable: phoneNavListenable,
      builder: (context, bottomNavVisible, _) {
        // Do NOT wrap the whole [Scaffold] in [MediaQuery.removeViewPadding]
        // (removeBottom: true): [BottomNavigationBar] reads
        // [MediaQuery.viewPaddingOf] bottom and adds that as insets to the
        // icon+label row (see Material bottom_navigation_bar.dart ~1107).
        // Stripping view padding here made labels sit flush on newer
        // Android gesture nav. Only the scrolling body should ignore the
        // bottom inset so content can extend behind the bar.
        final Color bodyColor = Theme.of(context).scaffoldBackgroundColor;

        Widget? bottomNavigationBar;
        if (bottomNavVisible) {
          bottomNavigationBar = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?phoneFooterAboveNav,
              _BottomNavBar(
                destinations: destinations,
                selectedIndex: displayIndex,
                onDestinationSelected: onDestinationSelected,
                onAdjacentDestinationSelected: onAdjacentDestinationSelected,
              ),
            ],
          );
        } else if (phoneFooterAboveNav != null) {
          // Mini-player chrome (e.g. QuranPlayerWidget) must stay visible on
          // shell routes that hide the bottom bar (/reciter/:id, search, …).
          // Bottom safe-area spacing is owned by the footer slot height.
          bottomNavigationBar = phoneFooterAboveNav!;
        }

        return Scaffold(
          backgroundColor: bodyColor,
          extendBody: false,
          body: MediaQuery.removeViewPadding(
            context: context,
            removeBottom: true,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeBottom: true,
                    child: child,
                  ),
                ),
                Positioned.fill(child: bottomPlayer),
              ],
            ),
          ),
          bottomNavigationBar: bottomNavigationBar,
        );
      },
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAdjacentDestinationSelected,
  });

  static const double _swipeVelocityThreshold = 220;

  final List<TilawaNavDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<TilawaNavAdjacentDirection>? onAdjacentDestinationSelected;

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final ValueChanged<TilawaNavAdjacentDirection>? callback =
        onAdjacentDestinationSelected;
    if (callback == null) {
      return;
    }

    final double? velocity = details.primaryVelocity;
    if (velocity == null ||
        velocity.abs() < _BottomNavBar._swipeVelocityThreshold) {
      return;
    }

    HapticFeedback.selectionClick();
    if (velocity < 0) {
      callback(TilawaNavAdjacentDirection.next);
    } else {
      callback(TilawaNavAdjacentDirection.previous);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaAdaptiveShellTokens tokens =
        theme.componentTokens.adaptiveShell;
    final TilawaBottomSheetScaffoldTokens sheetTokens =
        theme.componentTokens.bottomSheetScaffold;
    final MeMuslimDesignTokens designTokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final double hitSize = tokens.navButtonIconOnlyMinHeight;
    final double barHeight = hitSize + (2 * tokens.bottomNavInternalPadding);
    final double systemBottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final bool hasSelection = selectedIndex != null;
    final Color barColor = tokens.bottomNavBackgroundColor;
    final BorderRadius indicatorRadius = BorderRadius.circular(hitSize / 2);

    final SystemUiOverlayStyle bottomNavOverlayStyle = SystemUiOverlayStyle(
      systemNavigationBarColor: barColor.withValues(alpha: 1),
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          ThemeData.estimateBrightnessForColor(barColor) == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: bottomNavOverlayStyle,
      child: Material(
        key: const Key('tilawa_bottom_nav_dock'),
        color: barColor,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant,
                width: sheetTokens.footerTopBorderWidth,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: systemBottomInset),
            child: SizedBox(
              height: barHeight,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final int destinationCount = destinations.length;
                  final double slotWidth =
                      constraints.maxWidth / destinationCount;
                  final double indicatorWidth = math.min(
                    slotWidth - designTokens.spaceSmall,
                    hitSize + designTokens.spaceMedium,
                  );

                  return Material(
                    key: const Key('tilawa_bottom_nav_bar'),
                    color: Colors.transparent,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragEnd: _handleHorizontalDragEnd,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: tokens.bottomNavInternalPadding,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            if (hasSelection &&
                                destinations[selectedIndex!]
                                    .selectionUsesBackground)
                              AnimatedPositionedDirectional(
                                duration: designTokens.durationFast,
                                curve: Curves.easeOutCubic,
                                start:
                                    (selectedIndex! * slotWidth) +
                                    ((slotWidth - indicatorWidth) / 2),
                                width: indicatorWidth,
                                height: hitSize,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color:
                                        tokens.navButtonSelectedBackgroundColor,
                                    borderRadius: indicatorRadius,
                                  ),
                                ),
                              ),
                            Row(
                              children: [
                                for (int i = 0; i < destinations.length; i++)
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: _NavButton(
                                        key: Key('nav_button_$i'),
                                        destination: destinations[i],
                                        isSelected:
                                            hasSelection && selectedIndex == i,
                                        onTap: () => onDestinationSelected(i),
                                        indicatorRadius: indicatorRadius,
                                        targetWidth: indicatorWidth,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    super.key,
    required this.destination,
    required this.isSelected,
    required this.onTap,
    required this.indicatorRadius,
    required this.targetWidth,
  });

  final TilawaNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;
  final BorderRadius indicatorRadius;
  final double targetWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaAdaptiveShellTokens tokens =
        theme.componentTokens.adaptiveShell;
    final ColorScheme colorScheme = theme.colorScheme;
    final bool darkNavBg =
        ThemeData.estimateBrightnessForColor(tokens.bottomNavBackgroundColor) ==
        Brightness.dark;
    final Color selectedFg = darkNavBg
        ? AppColors.tripGlideInk
        : colorScheme.primary;
    final Color unselectedFg = darkNavBg
        ? AppColors.tripGlideSurface
        : colorScheme.onSurfaceVariant;
    final double hitSize = tokens.navButtonIconOnlyMinHeight;
    final Color pressStateLayerColor = darkNavBg
        ? AppColors.tripGlideSurface
        : colorScheme.primary;

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
            size: tokens.navButtonIconSize,
            color: isSelected ? selectedFg : unselectedFg,
          );

    return TilawaInteractiveSurface(
      button: true,
      semanticLabel: destination.label,
      semanticsIdentifier: destination.identifier,
      selected: isSelected,
      onTap: onTap,
      borderRadius: indicatorRadius,
      stateLayerColor: pressStateLayerColor,
      child: SizedBox(
        width: targetWidth,
        height: hitSize,
        child: Center(child: iconWidget),
      ),
    );
  }
}
