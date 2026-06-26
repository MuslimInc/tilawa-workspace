import 'dart:async';
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

/// Long-press expansion style for the phone bottom navigation bar.
///
/// Use [TilawaPhoneBottomNavLongPressMode.radial] (default) or
/// [TilawaPhoneBottomNavLongPressMode.verticalRight] to compare thumb-reach
/// selector patterns during UX evaluation.
enum TilawaPhoneBottomNavLongPressMode {
  /// Items fan along a semicircle anchored at the physical right thumb.
  radial,

  /// Items stack vertically on the physical right when long-pressing
  /// destination index `0` or `count - 1` (index-only). Middle destinations
  /// use the radial selector.
  verticalRight,
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
  /// photo with a ring) instead of the neutral circular fill.
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
    this.phoneBottomNavLongPressMode = TilawaPhoneBottomNavLongPressMode.radial,
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

  /// Long-press selector layout for the phone bottom nav bar.
  ///
  /// [verticalRight] stacks items on the physical right when long-pressing
  /// destination index `0` or `count - 1` (index-only; locale-independent);
  /// middle destinations fall back to the radial selector.
  final TilawaPhoneBottomNavLongPressMode phoneBottomNavLongPressMode;

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
                longPressMode: phoneBottomNavLongPressMode,
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

class _BottomNavBar extends StatefulWidget {
  const _BottomNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAdjacentDestinationSelected,
    required this.longPressMode,
  });

  static const double _swipeVelocityThreshold = 220;

  final List<TilawaNavDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<TilawaNavAdjacentDirection>? onAdjacentDestinationSelected;
  final TilawaPhoneBottomNavLongPressMode longPressMode;

  @override
  State<_BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<_BottomNavBar>
    with TickerProviderStateMixin {
  static const double _longPressMinFocusDistance = 20;
  // Pulse rises to this scale factor then returns to 1.0.
  static const double _pulseScale = 1.06;
  // Total pulse duration split evenly between rise and fall.
  static const Duration _pulseDuration = Duration(milliseconds: 280);

  late final AnimationController _longPressController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  int? _activePointer;
  int? _longPressOriginIndex;
  int? _longPressFocusedIndex;
  _VerticalStackAnchor? _verticalStackAnchor;
  final GlobalKey _navStackKey = GlobalKey();

  // Index currently being pulsed; null when idle.
  int? _pulsingIndex;
  // Set to true for the frame where onDestinationSelected is called by this
  // widget (user tap or long-press commit).  Cleared in didUpdateWidget so
  // that prop-driven index changes don't fire the pulse.
  bool _userInitiatedChange = false;

  @override
  void initState() {
    super.initState();
    _longPressController = AnimationController(vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: _pulseDuration,
    );
    // Rise: 1.0 → _pulseScale over first half; Fall: _pulseScale → 1.0 over second half.
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: _pulseScale,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: _pulseScale,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(_BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool indexChanged = widget.selectedIndex != oldWidget.selectedIndex;
    if (indexChanged && !_userInitiatedChange && widget.selectedIndex != null) {
      _pulsingIndex = widget.selectedIndex;
      _pulseController.forward(from: 0).then((_) {
        if (mounted) setState(() => _pulsingIndex = null);
      });
    }
    _userInitiatedChange = false;
  }

  @override
  void dispose() {
    _longPressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _notifyDestinationSelected(int index) {
    _userInitiatedChange = true;
    widget.onDestinationSelected(index);
  }

  bool get _isLongPressActive => _longPressOriginIndex != null;

  /// Vertical stack opens only from destination index `0` or `count - 1`.
  bool _usesVerticalStackSession(int count) {
    return _isLongPressActive &&
        widget.longPressMode ==
            TilawaPhoneBottomNavLongPressMode.verticalRight &&
        _verticalStackAnchor != null;
  }

  _VerticalStackAnchor? _verticalStackAnchorForOrigin(
    int originIndex,
    int count,
  ) {
    if (widget.longPressMode !=
        TilawaPhoneBottomNavLongPressMode.verticalRight) {
      return null;
    }
    if (originIndex == 0) {
      return _VerticalStackAnchor.first;
    }
    if (originIndex == count - 1) {
      return _VerticalStackAnchor.last;
    }
    return null;
  }

  Offset _verticalStackPivot({
    required int originIndex,
    required double width,
    required double stackHeight,
    required double hitSize,
    required double itemStride,
    required int count,
    required double innerVPadding,
    required bool isRtl,
  }) {
    return _barCenterForIndex(
      index: originIndex,
      width: width,
      stackHeight: stackHeight,
      hitSize: hitSize,
      itemStride: itemStride,
      count: count,
      innerVPadding: innerVPadding,
      isRtl: isRtl,
    );
  }

  Offset _barCenterForIndex({
    required int index,
    required double width,
    required double stackHeight,
    required double hitSize,
    required double itemStride,
    required int count,
    required double innerVPadding,
    required bool isRtl,
  }) {
    final double slotWidth = width / count;
    final int visualSlot = _LongPressNavLayout.visualSlotForDestinationIndex(
      destinationIndex: index,
      count: count,
      isRtl: isRtl,
    );
    return Offset(
      (visualSlot + 0.5) * slotWidth,
      stackHeight - innerVPadding - (hitSize / 2),
    );
  }

  /// Physical right-thumb anchor for long-press selectors (ignores text direction).
  Offset _thumbPivot({
    required double width,
    required double stackHeight,
    required double hitSize,
    required double innerVPadding,
    required double thumbSideInset,
  }) {
    return Offset(
      width - thumbSideInset - (hitSize / 2),
      stackHeight - innerVPadding - (hitSize / 2),
    );
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_isLongPressActive) {
      return;
    }
    final ValueChanged<TilawaNavAdjacentDirection>? callback =
        widget.onAdjacentDestinationSelected;
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

  void _startLongPressSession(int index) {
    final MeMuslimDesignTokens designTokens = Theme.of(context).tokens;
    final int count = widget.destinations.length;
    _longPressController.duration = designTokens.durationMedium;
    setState(() {
      _longPressOriginIndex = index;
      _longPressFocusedIndex = index;
      _verticalStackAnchor = _verticalStackAnchorForOrigin(index, count);
      _activePointer = null;
    });
    _longPressController.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _updateLongPressFocus(Offset globalPosition) {
    if (_longPressOriginIndex == null) {
      return;
    }
    final RenderBox? box =
        _navStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }

    final Offset localFinger = box.globalToLocal(globalPosition);
    final TilawaAdaptiveShellTokens tokens = Theme.of(
      context,
    ).componentTokens.adaptiveShell;
    final double hitSize = tokens.navButtonIconOnlyMinHeight;
    final double innerVPadding = tokens.bottomNavInternalPadding;
    final double itemStride = hitSize + tokens.bottomNavItemGap;
    final int count = widget.destinations.length;
    final _VerticalStackAnchor? verticalAnchor = _verticalStackAnchor;
    final int? originIndex = _longPressOriginIndex;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    final int nextIndex = switch (widget.longPressMode) {
      TilawaPhoneBottomNavLongPressMode.radial => _updateRadialFocusIndex(
        localFinger: localFinger,
        thumbPivot: _thumbPivot(
          width: box.size.width,
          stackHeight: box.size.height,
          hitSize: hitSize,
          innerVPadding: innerVPadding,
          thumbSideInset: tokens.bottomNavThumbSideMargin,
        ),
        count: count,
        hitSize: hitSize,
        isRtl: isRtl,
      ),
      TilawaPhoneBottomNavLongPressMode.verticalRight =>
        verticalAnchor != null && originIndex != null
            ? _VerticalNavLayout.nearestIndexFromFingerPosition(
                localFinger: localFinger,
                stackPivot: _verticalStackPivot(
                  originIndex: originIndex,
                  width: box.size.width,
                  stackHeight: box.size.height,
                  hitSize: hitSize,
                  itemStride: itemStride,
                  count: count,
                  innerVPadding: innerVPadding,
                  isRtl: isRtl,
                ),
                count: count,
                itemStride: itemStride,
                anchor: verticalAnchor,
              )
            : _updateRadialFocusIndex(
                localFinger: localFinger,
                thumbPivot: _thumbPivot(
                  width: box.size.width,
                  stackHeight: box.size.height,
                  hitSize: hitSize,
                  innerVPadding: innerVPadding,
                  thumbSideInset: tokens.bottomNavThumbSideMargin,
                ),
                count: count,
                hitSize: hitSize,
                isRtl: isRtl,
              ),
    };
    if (nextIndex == _longPressFocusedIndex) {
      return;
    }

    setState(() => _longPressFocusedIndex = nextIndex);
    HapticFeedback.selectionClick();
  }

  int _updateRadialFocusIndex({
    required Offset localFinger,
    required Offset thumbPivot,
    required int count,
    required double hitSize,
    required bool isRtl,
  }) {
    final double radialRadius = math.max(hitSize * 2.35, 92);
    final Offset circleCenter = _RadialNavLayout.circleCenterFromThumbPivot(
      thumbPivot: thumbPivot,
      radius: radialRadius,
    );
    final Offset delta = localFinger - circleCenter;
    if (delta.distance < _longPressMinFocusDistance) {
      return _longPressFocusedIndex ?? _longPressOriginIndex ?? 0;
    }

    return _RadialNavLayout.nearestIndexFromCircleCenter(
      delta,
      count,
      isRtl: isRtl,
    );
  }

  Future<void> _endLongPressSession({required bool commitSelection}) async {
    if (!_isLongPressActive) {
      return;
    }

    final int? focusedIndex = _longPressFocusedIndex;
    setState(() {
      _activePointer = null;
    });
    await _longPressController.reverse();
    if (!mounted) {
      return;
    }

    setState(() {
      _longPressOriginIndex = null;
      _longPressFocusedIndex = null;
      _verticalStackAnchor = null;
    });

    if (commitSelection && focusedIndex != null) {
      widget.onDestinationSelected(focusedIndex);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_isLongPressActive) {
      return;
    }
    _activePointer = event.pointer;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isLongPressActive) {
      return;
    }
    _activePointer ??= event.pointer;
    if (event.pointer != _activePointer) {
      return;
    }
    _updateLongPressFocus(event.position);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_isLongPressActive) {
      return;
    }
    if (_activePointer != null && event.pointer != _activePointer) {
      return;
    }
    unawaited(_endLongPressSession(commitSelection: true));
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (!_isLongPressActive || event.pointer != _activePointer) {
      return;
    }
    unawaited(_endLongPressSession(commitSelection: false));
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
    final bool hasSelection = widget.selectedIndex != null;
    final double radialRadius = math.max(hitSize * 2.35, 92);
    final double radialOverlayHeight =
        radialRadius + hitSize + designTokens.spaceLarge;
    // Vertical mode stacks items upward as an overlay; the dock keeps bar height
    // so body content is not cropped when the selector opens.
    final double stackHeight =
        _isLongPressActive &&
            (widget.longPressMode == TilawaPhoneBottomNavLongPressMode.radial ||
                !_usesVerticalStackSession(widget.destinations.length))
        ? radialOverlayHeight
        : barHeight;
    final int? focusedIndex = _longPressFocusedIndex ?? widget.selectedIndex;
    final Color barColor = tokens.bottomNavBackgroundColor;

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
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onPointerCancel: _handlePointerCancel,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isRtl =
                      Directionality.of(context) == TextDirection.rtl;
                  final int destinationCount = widget.destinations.length;
                  final double slotWidth =
                      constraints.maxWidth / destinationCount;
                  final double itemStride = slotWidth;
                  final double verticalPointerHeight =
                      barHeight + ((destinationCount - 1) * itemStride);
                  final bool useVerticalPointerOverflow =
                      _usesVerticalStackSession(destinationCount);
                  final _VerticalStackAnchor? verticalAnchor =
                      _verticalStackAnchor;
                  final int? originIndex = _longPressOriginIndex;
                  final double overlayStackHeight = useVerticalPointerOverflow
                      ? verticalPointerHeight
                      : stackHeight;
                  final Offset? verticalStackPivot =
                      useVerticalPointerOverflow && originIndex != null
                      ? _verticalStackPivot(
                          originIndex: originIndex,
                          width: constraints.maxWidth,
                          stackHeight: overlayStackHeight,
                          hitSize: hitSize,
                          itemStride: itemStride,
                          count: destinationCount,
                          innerVPadding: tokens.bottomNavInternalPadding,
                          isRtl: isRtl,
                        )
                      : null;
                  final Offset? radialThumbPivot =
                      _isLongPressActive && !useVerticalPointerOverflow
                      ? _thumbPivot(
                          width: constraints.maxWidth,
                          stackHeight: stackHeight,
                          hitSize: hitSize,
                          innerVPadding: tokens.bottomNavInternalPadding,
                          thumbSideInset: tokens.bottomNavThumbSideMargin,
                        )
                      : null;
                  Offset barCenterFor(int index) => _barCenterForIndex(
                    index: index,
                    width: constraints.maxWidth,
                    stackHeight: overlayStackHeight,
                    hitSize: hitSize,
                    itemStride: itemStride,
                    count: destinationCount,
                    innerVPadding: tokens.bottomNavInternalPadding,
                    isRtl: isRtl,
                  );

                  return AnimatedBuilder(
                    animation: _longPressController,
                    builder: (context, child) {
                      final double longPressT = _isLongPressActive
                          ? Curves.easeOutCubic.transform(
                              _longPressController.value,
                            )
                          : 0;

                      Widget navStack = SizedBox(
                        key: _navStackKey,
                        height: useVerticalPointerOverflow
                            ? verticalPointerHeight
                            : stackHeight,
                        width: constraints.maxWidth,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomCenter,
                          children: [
                            if (_isLongPressActive)
                              if (_usesVerticalStackSession(destinationCount) &&
                                  verticalStackPivot != null &&
                                  verticalAnchor != null)
                                _VerticalNavOverlay(
                                  key: const Key('tilawa_bottom_nav_vertical'),
                                  destinations: widget.destinations,
                                  stackPivot: verticalStackPivot,
                                  barCenterFor: barCenterFor,
                                  anchor: verticalAnchor,
                                  focusedIndex: focusedIndex ?? 0,
                                  progress: longPressT,
                                  hitSize: hitSize,
                                  itemStride: itemStride,
                                  tokens: tokens,
                                  designTokens: designTokens,
                                  colorScheme: colorScheme,
                                )
                              else if (radialThumbPivot != null)
                                _RadialNavOverlay(
                                  key: const Key('tilawa_bottom_nav_radial'),
                                  destinations: widget.destinations,
                                  thumbPivot: radialThumbPivot,
                                  barCenterFor: barCenterFor,
                                  isRtl: isRtl,
                                  focusedIndex: focusedIndex ?? 0,
                                  progress: longPressT,
                                  hitSize: hitSize,
                                  radialRadius: radialRadius,
                                  tokens: tokens,
                                  designTokens: designTokens,
                                  colorScheme: colorScheme,
                                ),
                            AnimatedOpacity(
                              duration: designTokens.durationFast,
                              opacity: _isLongPressActive ? 0 : 1,
                              child: IgnorePointer(
                                ignoring: _isLongPressActive,
                                child: child,
                              ),
                            ),
                          ],
                        ),
                      );

                      if (useVerticalPointerOverflow) {
                        navStack = SizedBox(
                          height: stackHeight,
                          width: constraints.maxWidth,
                          child: OverflowBox(
                            alignment: Alignment.bottomCenter,
                            minHeight: verticalPointerHeight,
                            maxHeight: verticalPointerHeight,
                            child: navStack,
                          ),
                        );
                      }

                      return navStack;
                    },
                    child: Material(
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
                                  widget
                                      .destinations[widget.selectedIndex!]
                                      .selectionUsesBackground)
                                AnimatedPositionedDirectional(
                                  duration: designTokens.durationFast,
                                  curve: Curves.easeOutCubic,
                                  start:
                                      (widget.selectedIndex! * slotWidth) +
                                      ((slotWidth - hitSize) / 2),
                                  width: hitSize,
                                  height: hitSize,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: tokens
                                          .navButtonSelectedBackgroundColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              Row(
                                children: [
                                  for (
                                    int i = 0;
                                    i < widget.destinations.length;
                                    i++
                                  )
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: _NavButton(
                                          key: Key('nav_button_$i'),
                                          destination: widget.destinations[i],
                                          isSelected:
                                              hasSelection &&
                                              widget.selectedIndex == i,
                                          onTap: () =>
                                              _notifyDestinationSelected(i),
                                          onLongPress: () =>
                                              _startLongPressSession(i),
                                          pulseAnimation: _pulsingIndex == i
                                              ? _pulseAnimation
                                              : null,
                                          pulseKey: Key('nav_pulse_$i'),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
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

/// Shared visual slot mapping for long-press selectors (bar order ↔ thumb side).
abstract final class _LongPressNavLayout {
  static int visualSlotForDestinationIndex({
    required int destinationIndex,
    required int count,
    required bool isRtl,
  }) {
    return isRtl ? count - 1 - destinationIndex : destinationIndex;
  }

  static int destinationIndexForVisualSlot({
    required int visualSlot,
    required int count,
    required bool isRtl,
  }) {
    return isRtl ? count - 1 - visualSlot : visualSlot;
  }
}

/// Right-thumb radial layout: circle center sits to the left of the thumb pivot.
abstract final class _RadialNavLayout {
  static Offset circleCenterFromThumbPivot({
    required Offset thumbPivot,
    required double radius,
  }) {
    return thumbPivot + Offset(-radius, 0);
  }

  static Offset offsetOnCircle({
    required int index,
    required int count,
    required double radius,
  }) {
    if (count <= 1) {
      return Offset(radius, 0);
    }

    final double startAngle = math.pi;
    final double sweep = math.pi;
    final double angle = startAngle + (index / (count - 1)) * sweep;
    return Offset(math.cos(angle) * radius, math.sin(angle) * radius);
  }

  static Offset offsetFromThumbPivot({
    required int index,
    required int count,
    required double radius,
    required bool isRtl,
  }) {
    final int visualSlot = _LongPressNavLayout.visualSlotForDestinationIndex(
      destinationIndex: index,
      count: count,
      isRtl: isRtl,
    );
    return Offset(-radius, 0) +
        offsetOnCircle(index: visualSlot, count: count, radius: radius);
  }

  static int nearestIndexFromCircleCenter(
    Offset delta,
    int count, {
    required bool isRtl,
  }) {
    if (count <= 1) {
      return 0;
    }

    var bestVisualSlot = 0;
    var bestDistance = double.infinity;
    for (var visualSlot = 0; visualSlot < count; visualSlot++) {
      final Offset slot = offsetOnCircle(
        index: visualSlot,
        count: count,
        radius: 1,
      );
      final double distance = (delta - slot).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestVisualSlot = visualSlot;
      }
    }
    return _LongPressNavLayout.destinationIndexForVisualSlot(
      visualSlot: bestVisualSlot,
      count: count,
      isRtl: isRtl,
    );
  }
}

/// Which destination index is anchored at the bottom of a vertical stack.
enum _VerticalStackAnchor {
  /// Index `0` at bottom; higher indices stack upward.
  first,

  /// Index `count - 1` at bottom; lower indices stack upward.
  last,
}

/// Vertical stack above the long-pressed edge item (layout is index-only).
abstract final class _VerticalNavLayout {
  static int slotFromBottomAnchor({
    required int index,
    required int count,
    required _VerticalStackAnchor anchor,
  }) {
    return switch (anchor) {
      _VerticalStackAnchor.first => index,
      _VerticalStackAnchor.last => (count - 1) - index,
    };
  }

  static Offset offsetFromStackPivot({
    required int index,
    required int count,
    required _VerticalStackAnchor anchor,
    required double itemStride,
  }) {
    final int slot = slotFromBottomAnchor(
      index: index,
      count: count,
      anchor: anchor,
    );
    return Offset(0, -slot * itemStride);
  }

  /// Keeps X on the pressed item; only Y animates from the bar row.
  static Offset offsetForProgress({
    required Offset barCenter,
    required Offset stackPivot,
    required int index,
    required int count,
    required _VerticalStackAnchor anchor,
    required double itemStride,
    required double progress,
  }) {
    final Offset end = offsetFromStackPivot(
      index: index,
      count: count,
      anchor: anchor,
      itemStride: itemStride,
    );
    final double startDy = barCenter.dy - stackPivot.dy;
    return Offset(0, startDy + ((end.dy - startDy) * progress));
  }

  static int nearestIndexFromFingerPosition({
    required Offset localFinger,
    required Offset stackPivot,
    required int count,
    required double itemStride,
    required _VerticalStackAnchor anchor,
  }) {
    if (count <= 1) {
      return 0;
    }

    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var index = 0; index < count; index++) {
      final Offset itemCenter =
          stackPivot +
          offsetFromStackPivot(
            index: index,
            count: count,
            anchor: anchor,
            itemStride: itemStride,
          );
      final double distance = (localFinger - itemCenter).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index;
      }
    }
    return bestIndex;
  }
}

class _RadialNavOverlay extends StatelessWidget {
  const _RadialNavOverlay({
    super.key,
    required this.destinations,
    required this.thumbPivot,
    required this.barCenterFor,
    required this.isRtl,
    required this.focusedIndex,
    required this.progress,
    required this.hitSize,
    required this.radialRadius,
    required this.tokens,
    required this.designTokens,
    required this.colorScheme,
  });

  final List<TilawaNavDestination> destinations;
  final Offset thumbPivot;
  final Offset Function(int index) barCenterFor;
  final bool isRtl;
  final int focusedIndex;
  final double progress;
  final double hitSize;
  final double radialRadius;
  final TilawaAdaptiveShellTokens tokens;
  final MeMuslimDesignTokens designTokens;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final int count = destinations.length;
    final double ringDiameter = radialRadius * 2 * progress;
    final Offset circleCenter = _RadialNavLayout.circleCenterFromThumbPivot(
      thumbPivot: thumbPivot,
      radius: radialRadius * progress,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: circleCenter.dx - radialRadius * progress,
          top: circleCenter.dy - radialRadius * progress,
          child: Opacity(
            opacity: progress * 0.9,
            child: Container(
              width: ringDiameter,
              height: ringDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.bottomNavBackgroundColor,
                border: Border.all(
                  color: tokens.bottomNavOutlineColor,
                  width: tokens.bottomNavBorderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(
                      alpha: tokens.bottomNavShadowOpacity * 2.5,
                    ),
                    blurRadius: tokens.bottomNavShadowBlur * 1.5,
                    offset: tokens.bottomNavShadowOffset,
                  ),
                ],
              ),
            ),
          ),
        ),
        for (var index = 0; index < count; index++)
          _LongPressNavItem(
            destination: destinations[index],
            offset: Offset.lerp(
              barCenterFor(index) - thumbPivot,
              _RadialNavLayout.offsetFromThumbPivot(
                index: index,
                count: count,
                radius: radialRadius,
                isRtl: isRtl,
              ),
              progress,
            )!,
            thumbPivot: thumbPivot,
            hitSize: hitSize,
            isFocused: index == focusedIndex,
            showFocusedLabel: true,
            tokens: tokens,
            colorScheme: colorScheme,
            designTokens: designTokens,
          ),
      ],
    );
  }
}

class _VerticalNavOverlay extends StatelessWidget {
  const _VerticalNavOverlay({
    super.key,
    required this.destinations,
    required this.stackPivot,
    required this.barCenterFor,
    required this.anchor,
    required this.focusedIndex,
    required this.progress,
    required this.hitSize,
    required this.itemStride,
    required this.tokens,
    required this.designTokens,
    required this.colorScheme,
  });

  final List<TilawaNavDestination> destinations;
  final Offset stackPivot;
  final Offset Function(int index) barCenterFor;
  final _VerticalStackAnchor anchor;
  final int focusedIndex;
  final double progress;
  final double hitSize;
  final double itemStride;
  final TilawaAdaptiveShellTokens tokens;
  final MeMuslimDesignTokens designTokens;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final int count = destinations.length;
    final double railInset = tokens.bottomNavInternalPadding;
    final double contentHeight = hitSize + ((count - 1) * itemStride);
    final double railHeight = contentHeight + (2 * railInset * progress);
    final double railWidth = hitSize + designTokens.spaceSmall;
    final double railTop =
        stackPivot.dy + (hitSize / 2) + (railInset * progress) - railHeight;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: stackPivot.dx - (railWidth / 2),
          top: railTop,
          child: Opacity(
            opacity: progress * 0.92,
            child: Container(
              width: railWidth,
              height: railHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(railWidth / 2),
                color: tokens.bottomNavBackgroundColor,
                border: Border.all(
                  color: tokens.bottomNavOutlineColor,
                  width: tokens.bottomNavBorderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(
                      alpha: tokens.bottomNavShadowOpacity * 2.5,
                    ),
                    blurRadius: tokens.bottomNavShadowBlur * 1.5,
                    offset: tokens.bottomNavShadowOffset,
                  ),
                ],
              ),
            ),
          ),
        ),
        for (var index = 0; index < count; index++)
          _LongPressNavItem(
            destination: destinations[index],
            offset: _VerticalNavLayout.offsetForProgress(
              barCenter: barCenterFor(index),
              stackPivot: stackPivot,
              index: index,
              count: count,
              anchor: anchor,
              itemStride: itemStride,
              progress: progress,
            ),
            thumbPivot: stackPivot,
            hitSize: hitSize,
            isFocused: index == focusedIndex,
            showFocusedLabel: false,
            tokens: tokens,
            colorScheme: colorScheme,
            designTokens: designTokens,
          ),
      ],
    );
  }
}

class _LongPressNavItem extends StatelessWidget {
  const _LongPressNavItem({
    required this.destination,
    required this.offset,
    required this.thumbPivot,
    required this.hitSize,
    required this.isFocused,
    required this.showFocusedLabel,
    required this.tokens,
    required this.colorScheme,
    required this.designTokens,
  });

  final TilawaNavDestination destination;
  final Offset offset;
  final Offset thumbPivot;
  final double hitSize;
  final bool isFocused;
  final bool showFocusedLabel;
  final TilawaAdaptiveShellTokens tokens;
  final ColorScheme colorScheme;
  final MeMuslimDesignTokens designTokens;

  @override
  Widget build(BuildContext context) {
    final bool darkNavBg =
        ThemeData.estimateBrightnessForColor(tokens.bottomNavBackgroundColor) ==
        Brightness.dark;
    final Color selectedFg = darkNavBg
        ? AppColors.tripGlideInk
        : colorScheme.primary;
    final Color unselectedFg = darkNavBg
        ? AppColors.tripGlideSurface
        : colorScheme.onSurfaceVariant;
    final Color foreground = isFocused ? selectedFg : unselectedFg;
    final double scale = isFocused ? 1.12 : 0.94;

    final Widget iconWidget = destination.iconBuilder != null
        ? destination.iconBuilder!(
            context,
            isSelected: isFocused,
            color: foreground,
          )
        : Icon(
            isFocused
                ? (destination.activeIcon ?? destination.icon)
                : destination.icon,
            size: tokens.navButtonIconSize,
            color: foreground,
          );

    return Positioned(
      left: thumbPivot.dx + offset.dx - (hitSize / 2),
      top: thumbPivot.dy + offset.dy - (hitSize / 2),
      child: Transform.scale(
        scale: scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: isFocused && destination.selectionUsesBackground
                    ? tokens.navButtonSelectedBackgroundColor
                    : tokens.bottomNavBackgroundColor.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isFocused
                      ? selectedFg.withValues(alpha: 0.35)
                      : tokens.bottomNavOutlineColor,
                  width: tokens.bottomNavBorderWidth,
                ),
              ),
              child: SizedBox(
                width: hitSize,
                height: hitSize,
                child: Center(child: iconWidget),
              ),
            ),
            if (isFocused && showFocusedLabel) ...[
              SizedBox(height: designTokens.spaceExtraSmall),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
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
    this.onLongPress,
    this.pulseAnimation,
    this.pulseKey,
  });

  final TilawaNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Non-null only when a programmatic index change just selected this item.
  final Animation<double>? pulseAnimation;

  /// Key placed on the [ScaleTransition] wrapper for test introspection.
  final Key? pulseKey;

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

    Widget iconWidget = destination.iconBuilder != null
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

    final Animation<double>? pulse = pulseAnimation;
    if (pulse != null) {
      iconWidget = ScaleTransition(
        key: pulseKey,
        scale: pulse,
        child: iconWidget,
      );
    } else {
      // Always emit the ScaleTransition node (at fixed scale 1.0) so tests
      // can find it by key regardless of animation state.
      iconWidget = ScaleTransition(
        key: pulseKey,
        scale: const AlwaysStoppedAnimation<double>(1.0),
        child: iconWidget,
      );
    }

    return Semantics(
      button: true,
      label: destination.label,
      selected: isSelected,
      identifier: destination.identifier,
      child: TilawaInteractiveSurface(
        // Outer Semantics owns the role/label/selected/identifier.
        button: false,
        onTap: onTap,
        onLongPress: onLongPress,
        // Circular focus ring + state layer for the round nav target.
        borderRadius: BorderRadius.circular(hitSize / 2),
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: Center(child: iconWidget),
        ),
      ),
    );
  }
}
