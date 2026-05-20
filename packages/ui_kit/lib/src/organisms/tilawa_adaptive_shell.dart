import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/breakpoints.dart';
import '../foundation/component_tokens.dart';
import '../foundation/content_bounds.dart';
import '../foundation/design_tokens.dart';
import '../foundation/display_feature_insets.dart';
import '../foundation/safe_area_ext.dart';

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
/// - Phone (narrow): [BottomNavigationBar] is laid out in a [Column] under an
///   [Expanded] body region (not [Scaffold.bottomNavigationBar]) so nested
///   tab [Scaffold]s receive bounded constraints. Destination **labels are always
///   shown** (icons + text). Optional [phoneBottomNavigationBarVisible] can hide
///   the bar (e.g. full-screen player). [Scaffold.extendBody] is false.
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
    this.phoneFooterAboveNav,
    this.phoneBottomNavigationBarVisible,
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

  /// Optional chrome laid out directly above the phone [BottomNavigationBar]
  /// (e.g. a mini media player). Rendered below the scrolling body, not as a
  /// full-screen overlay on top of it.
  final Widget? phoneFooterAboveNav;

  /// When non-null, narrow (phone) window class shows the bottom bar only
  /// while this value is
  /// true (e.g. hide while a full-screen sheet covers the tab bar).
  final ValueListenable<bool>? phoneBottomNavigationBarVisible;

  /// Optional padding for the bottom bar on phone layouts.
  final EdgeInsetsGeometry? bottomBarPadding;

  /// Optional decoration for the bottom bar on phone layouts.
  final Decoration? bottomBarDecoration;

  /// Whether to avoid placing content under display features (hinges/folds).
  /// Defaults to true. Set to false to disable foldable-aware padding.
  final bool avoidDisplayFeatures;

  @override
  Widget build(BuildContext context) {
    final windowSize = context.windowSize;
    final displayIndex = (selectedIndex == -1) ? null : selectedIndex;
    final bool isKeyboardOpen = context.isKeyboardVisible;

    if (windowSize == TilawaWindowSize.narrow) {
      final ValueListenable<bool> phoneNavListenable =
          phoneBottomNavigationBarVisible ?? _kAlwaysShowPhoneBottomNav;

      final Color shellChromeColor = Theme.of(
        context,
      ).componentTokens.adaptiveShell.bottomNavBackgroundColor;

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
          return Scaffold(
            backgroundColor: shellChromeColor,
            extendBody: false,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: MediaQuery.removeViewPadding(
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
                ),
                if (isKeyboardOpen || !bottomNavVisible)
                  const SizedBox.shrink()
                else if (phoneFooterAboveNav != null) ...[
                  phoneFooterAboveNav!,
                  SizedBox(height: Theme.of(context).tokens.spaceSmall),
                ],
                if (isKeyboardOpen || !bottomNavVisible)
                  const SizedBox.shrink()
                else
                  _BottomNavBar(
                    destinations: destinations,
                    selectedIndex: displayIndex,
                    onDestinationSelected: onDestinationSelected,
                    padding: bottomBarPadding,
                    decoration: bottomBarDecoration,
                  ),
              ],
            ),
          );
        },
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

  static BottomNavigationBarItem _barItem(
    BuildContext context,
    TilawaNavDestination destination,
    TilawaAdaptiveShellTokens tokens,
    ThemeData theme, {
    required bool tabIsSelected,
  }) {
    final Color inactiveColor = theme.colorScheme.onSurfaceVariant;
    final Color activeColor = theme.colorScheme.primary;

    Widget inactiveGlyph = destination.iconBuilder != null
        ? destination.iconBuilder!(
            context,
            isSelected: false,
            color: inactiveColor,
          )
        : Icon(
            destination.icon,
            size: tokens.navButtonIconSize,
            color: inactiveColor,
          );

    Widget activeGlyph = destination.iconBuilder != null
        ? destination.iconBuilder!(
            context,
            isSelected: true,
            color: activeColor,
          )
        : Icon(
            destination.activeIcon ?? destination.icon,
            size: tokens.navButtonIconSize,
            color: activeColor,
          );

    if (destination.identifier != null) {
      inactiveGlyph = Semantics(
        identifier: destination.identifier,
        child: inactiveGlyph,
      );
      activeGlyph = Semantics(
        identifier: destination.identifier,
        child: activeGlyph,
      );
    }

    inactiveGlyph = Padding(
      padding: EdgeInsets.only(bottom: tokens.navButtonGap),
      child: inactiveGlyph,
    );
    activeGlyph = Padding(
      padding: EdgeInsets.only(bottom: tokens.navButtonGap),
      child: activeGlyph,
    );

    return BottomNavigationBarItem(
      icon: inactiveGlyph,
      activeIcon: tabIsSelected ? activeGlyph : inactiveGlyph,
      label: destination.label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.adaptiveShell;
    final Color navColor = tokens.bottomNavBackgroundColor;

    final int count = destinations.length;
    final bool hasSelection = selectedIndex != null;
    final int barIndex = hasSelection ? selectedIndex!.clamp(0, count - 1) : 0;

    final TextStyle baseLabel = theme.textTheme.labelSmall ?? const TextStyle();
    final TextStyle selectedLabelStyle = baseLabel.copyWith(
      fontSize: tokens.navButtonLabelFontSize,
      fontWeight: tokens.navButtonSelectedLabelWeight,
      height: 1.15,
    );
    final TextStyle unselectedLabelStyle = baseLabel.copyWith(
      fontSize: tokens.navButtonLabelFontSize,
      fontWeight: tokens.navButtonUnselectedLabelWeight,
      height: 1.15,
    );

    // [BottomNavigationBar] applies [MediaQuery.withClampedTextScaling] with
    // max 1.0 on labels. Nesting that on an already clamped [TextScaler] whose
    // minimum exceeds 1.0 can compose invalid bounds (assert in
    // [_ClampedTextScaler]). Use a linear scaler capped to 1.0 so Material's
    // internal clamp stays on the [_LinearTextScaler] path.
    final double bottomBarTextScale = MediaQuery.textScalerOf(
      context,
    ).scale(1.0).clamp(0.01, 1.0);

    final SystemUiOverlayStyle bottomNavOverlayStyle = SystemUiOverlayStyle(
      systemNavigationBarColor: navColor.withValues(alpha: 1),
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          ThemeData.estimateBrightnessForColor(navColor) == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: bottomNavOverlayStyle,
      child: ColoredBox(
        color: navColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TilawaContentBounds(
              kind: TilawaContentKind.media,
              alignment: .bottomCenter,
              child: Padding(
                padding:
                    padding ??
                    EdgeInsets.fromLTRB(
                      tokens.bottomNavHorizontalMargin,
                      0,
                      tokens.bottomNavHorizontalMargin,
                      0,
                    ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
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
                      side: BorderSide(
                        color: tokens.bottomNavOutlineColor,
                        width: tokens.bottomNavBorderWidth,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: DecoratedBox(
                      decoration: decoration ?? const BoxDecoration(),
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(bottomBarTextScale),
                        ),
                        child: Theme(
                          data: theme.copyWith(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                          ),
                          child: BottomNavigationBar(
                            type: BottomNavigationBarType.fixed,
                            currentIndex: barIndex,
                            onTap: (int index) {
                              HapticFeedback.selectionClick();
                              onDestinationSelected(index);
                            },
                            showSelectedLabels: true,
                            showUnselectedLabels: true,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            selectedItemColor: hasSelection
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            unselectedItemColor:
                                theme.colorScheme.onSurfaceVariant,
                            selectedLabelStyle: selectedLabelStyle,
                            unselectedLabelStyle: unselectedLabelStyle,
                            selectedIconTheme: IconThemeData(
                              size: tokens.navButtonIconSize,
                              color: hasSelection
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            unselectedIconTheme: IconThemeData(
                              size: tokens.navButtonIconSize,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            items: [
                              for (int i = 0; i < count; i++)
                                _barItem(
                                  context,
                                  destinations[i],
                                  tokens,
                                  theme,
                                  tabIsSelected:
                                      hasSelection && selectedIndex == i,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
