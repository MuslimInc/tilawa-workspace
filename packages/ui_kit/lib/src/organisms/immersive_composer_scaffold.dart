import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/tilawa_icons.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/safe_area_ext.dart';

/// Hint about the kind of content the scaffold's [preview] is showing.
///
/// Drives the default value of [ImmersiveComposerScaffold.disableBlur]
/// when the caller doesn't pass an explicit override:
///
/// * [ui] — the preview is a UI surface (default). Blur stays on.
/// * [media] — the preview is a photo, image, or video. Blur turns off
///   so the bottom panel reads clearly against varying media tones.
enum BackgroundIntent { ui, media }

/// Immersive three-layer scaffold: full-bleed [preview] content with a
/// top app bar overlay and a bottom panel overlay.
///
/// Overlays never resize the content — they float above it and manage
/// their own safe-area insets. Visibility can be driven externally via
/// [overlaysVisible]; otherwise the scaffold owns the state internally.
class ImmersiveComposerScaffold extends StatefulWidget {
  const ImmersiveComposerScaffold({
    super.key,
    required this.title,
    required this.preview,
    required this.bottomPanel,
    this.subtitle,
    this.onClose,
    this.leading,
    this.trailing,
    this.background,
    this.backgroundGradient,
    this.floatingActionButton,
    this.overlaysVisible,
    this.onVisibilityChanged,
    this.disableBlur,
    this.backgroundIntent = BackgroundIntent.ui,
  });

  final String title;
  final String? subtitle;
  final Widget preview;
  final Widget bottomPanel;
  final VoidCallback? onClose;
  final Widget? leading;
  final Widget? trailing;
  final Widget? background;
  final Gradient? backgroundGradient;
  final Widget? floatingActionButton;

  /// When non-null, overrides internal visibility state. The scaffold
  /// becomes a controlled widget — pair with [onVisibilityChanged] to
  /// observe user-driven toggles.
  final bool? overlaysVisible;

  /// Fires when the user toggles visibility (tap).
  /// Always fires, whether controlled or not.
  final ValueChanged<bool>? onVisibilityChanged;

  /// Whether to skip the backdrop blur on the overlays.
  ///
  /// When `null` (default), the value is derived from [backgroundIntent]:
  /// blur is disabled for [BackgroundIntent.media] and enabled for
  /// [BackgroundIntent.ui]. Pass an explicit `true`/`false` to override.
  final bool? disableBlur;

  /// Hints what kind of content the [preview] is showing. Drives the
  /// default value of [disableBlur] when not explicitly set.
  final BackgroundIntent backgroundIntent;

  /// Resolved blur preference: explicit [disableBlur] wins; otherwise
  /// derived from [backgroundIntent].
  bool get effectiveDisableBlur =>
      disableBlur ?? backgroundIntent == BackgroundIntent.media;

  @override
  State<ImmersiveComposerScaffold> createState() =>
      _ImmersiveComposerScaffoldState();
}

class _ImmersiveComposerScaffoldState extends State<ImmersiveComposerScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _topOffset;
  late final Animation<Offset> _bottomOffset;
  bool _isVisible = true;
  bool _hasBeenShown = true;

  @override
  void initState() {
    super.initState();
    _isVisible = widget.overlaysVisible ?? true;
    _hasBeenShown = _isVisible;
    _controller = AnimationController(
      vsync: this,
      duration: TilawaImmersiveComposerTokens.defaults().transitionDuration,
    );

    _controller.value = _isVisible ? 1.0 : 0.0;

    _topOffset = Tween<Offset>(
      begin: const Offset(0, -1.2), // Off-screen top
      end: .zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _bottomOffset = Tween<Offset>(
      begin: const Offset(0, 1.2), // Off-screen bottom
      end: .zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(ImmersiveComposerScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.overlaysVisible != oldWidget.overlaysVisible &&
        widget.overlaysVisible != null) {
      if (widget.overlaysVisible!) {
        _isVisible = true;
        _hasBeenShown = true;
        _controller.forward();
      } else {
        _isVisible = false;
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setVisible(bool next) {
    if (next == _isVisible) {
      return;
    }
    setState(() {
      _isVisible = next;
      if (next) _hasBeenShown = true;
    });
    if (next) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    widget.onVisibilityChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = context.contentSafePadding;
    final systemSafeArea = context.systemSafeArea;
    final overlayStyle = _buildSystemUiOverlayStyle(theme);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          clipBehavior: .none,
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: theme
                    .componentTokens
                    .immersiveComposer
                    .composerSurfaceColor,
              ),
            ),

            if (systemSafeArea.top > 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: systemSafeArea.top,
                child: ColoredBox(
                  color: theme
                      .componentTokens
                      .immersiveComposer
                      .composerSurfaceColor,
                ),
              ),

            if (systemSafeArea.bottom > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: systemSafeArea.bottom,
                child: ColoredBox(
                  color: theme
                      .componentTokens
                      .immersiveComposer
                      .composerSurfaceColor,
                ),
              ),

            // 1. Background Layer (Isolated)
            if (widget.backgroundGradient != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: widget.backgroundGradient,
                  ),
                ),
              ),
            if (widget.background != null)
              Positioned.fill(
                child: RepaintBoundary(child: widget.background!),
              ),

            // 2. Gesture/Preview Layer (Wrapped in RepaintBoundary to prevent repaints during overlay animations)
            Positioned.fill(
              child: RepaintBoundary(
                child: GestureDetector(
                  behavior: .translucent,
                  onTap: () => _setVisible(!_isVisible),
                  child: SafeArea(child: widget.preview),
                ),
              ),
            ),

            // 3. Top Overlay (Slide only, no Fade)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _topOffset,
                child: IgnorePointer(
                  ignoring: !_isVisible,
                  child: RepaintBoundary(
                    child: Listener(
                      onPointerDown: (_) => _setVisible(true),
                      child: _hasBeenShown
                          ? _OverlayPanel(
                              disableBlur: widget.effectiveDisableBlur,
                              child: SafeArea(
                                bottom: false,
                                child: _TopAppBar(
                                  title: widget.title,
                                  subtitle: widget.subtitle,
                                  leading: widget.leading,
                                  trailing: widget.trailing,
                                  onClose: widget.onClose,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),

            // 4. Bottom Overlay (Slide only, no Fade)
            Positioned(
              left: 0,
              right: 0,
              bottom: -padding.bottom,
              child: SlideTransition(
                position: _bottomOffset,
                child: IgnorePointer(
                  ignoring: !_isVisible,
                  child: RepaintBoundary(
                    child: Listener(
                      onPointerDown: (_) => _setVisible(true),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: padding.bottom),
                        child: _hasBeenShown
                            ? _OverlayPanel(
                                disableBlur: widget.effectiveDisableBlur,
                                child: widget.bottomPanel,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (widget.floatingActionButton != null)
              PositionedDirectional(
                end: theme.tokens.spaceMedium,
                bottom: theme.tokens.spaceMedium + padding.bottom,
                child: ScaleTransition(
                  scale: _controller,
                  child: IgnorePointer(
                    ignoring: !_isVisible,
                    child: RepaintBoundary(child: widget.floatingActionButton!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  SystemUiOverlayStyle _buildSystemUiOverlayStyle(ThemeData theme) {
    final barColor =
        theme.componentTokens.immersiveComposer.composerSurfaceColor;
    final barBrightness = ThemeData.estimateBrightnessForColor(barColor);
    final iconBrightness = barBrightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    return SystemUiOverlayStyle(
      statusBarColor: barColor,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: barBrightness,
      systemNavigationBarColor: barColor,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: iconBrightness,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );
  }
}

/// Simplified panel that avoids BackdropFilter and uses opaque background.
class _OverlayPanel extends StatelessWidget {
  const _OverlayPanel({required this.disableBlur, required this.child});

  final bool disableBlur;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final componentTokens = theme.componentTokens.immersiveComposer;

    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: disableBlur
            ? componentTokens.composerSurfaceColor
            : componentTokens.overlayPanelTranslucentFillColor,
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(family: TilawaRadiusFamily.chrome),
        ),
        border: Border.all(color: componentTokens.panelBorderColor),
      ),
      child: child,
    );

    if (disableBlur) return panel;

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        tokens.resolveRadius(family: TilawaRadiusFamily.chrome),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: tokens.blurGlass * componentTokens.backgroundBlurScale,
          sigmaY: tokens.blurGlass * componentTokens.backgroundBlurScale,
        ),
        child: panel,
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.trailing,
    required this.onClose,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.immersiveComposer;

    final titleStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: .bold);
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: componentTokens.topBarSubtitleColor,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: componentTokens.composerSurfaceColor,
        borderRadius: BorderRadius.circular(
          designTokens.resolveRadius(family: TilawaRadiusFamily.chrome),
        ),
        border: Border.all(color: componentTokens.panelBorderColor),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: designTokens.spaceLarge,
          vertical: designTokens.spaceSmall,
        ),
        child: Row(
          children: [
            leading ??
                _RoundHeaderButton(
                  icon: TilawaIcons.dismiss,
                  onPressed: onClose,
                ),
            Expanded(
              child: Column(
                mainAxisSize: .min,
                children: [
                  Text(title, textAlign: .center, style: titleStyle),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      textAlign: .center,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: subtitleStyle,
                    ),
                ],
              ),
            ),
            trailing ??
                SizedBox(
                  width: componentTokens.headerButtonSize,
                  height: componentTokens.headerButtonSize,
                ),
          ],
        ),
      ),
    );
  }
}

class _RoundHeaderButton extends StatelessWidget {
  const _RoundHeaderButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final componentTokens = theme.componentTokens.immersiveComposer;

    return Container(
      width: componentTokens.headerButtonSize,
      height: componentTokens.headerButtonSize,
      decoration: BoxDecoration(
        shape: .circle,
        color: componentTokens.headerIconButtonFillColor,
      ),
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(padding: .zero),
        iconSize: theme.tokens.iconSizeMedium,
        icon: Icon(icon),
      ),
    );
  }
}
