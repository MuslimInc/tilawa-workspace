import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

/// Immersive three-layer scaffold: full-bleed [preview] content with a
/// top app bar overlay and a bottom panel overlay that auto-hide on
/// inactivity.
///
/// Overlays never resize the content — they float above it and manage
/// their own safe-area insets. Visibility can be driven externally via
/// [overlaysVisible]; otherwise the scaffold owns the state internally
/// (tap to toggle, auto-hide after [autoHideDuration]).
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
    this.autoHideDuration = const Duration(seconds: 3),
    this.enableAutoHide = true,
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

  /// Fires when the user toggles visibility (tap) or the auto-hide
  /// timer elapses. Always fires, whether controlled or not.
  final ValueChanged<bool>? onVisibilityChanged;

  final Duration autoHideDuration;
  final bool enableAutoHide;

  @override
  State<ImmersiveComposerScaffold> createState() =>
      _ImmersiveComposerScaffoldState();
}

class _ImmersiveComposerScaffoldState extends State<ImmersiveComposerScaffold> {
  static const Duration _animationDuration = Duration(milliseconds: 200);

  bool _internalVisible = true;
  Timer? _hideTimer;

  bool get _visible => widget.overlaysVisible ?? _internalVisible;

  @override
  void initState() {
    super.initState();
    _restartHideTimer();
  }

  @override
  void didUpdateWidget(covariant ImmersiveComposerScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_visible) {
      _restartHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    if (!_visible || !widget.enableAutoHide) return;
    _hideTimer = Timer(widget.autoHideDuration, () {
      _setVisible(false);
    });
  }

  void _setVisible(bool next) {
    if (_visible == next) return;
    if (widget.overlaysVisible == null) {
      setState(() => _internalVisible = next);
    }
    widget.onVisibilityChanged?.call(next);
    if (next) _restartHideTimer();
  }

  void _handleTap() => _setVisible(!_visible);

  void _handleInteraction() {
    if (_visible) _restartHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.immersiveComposer;

    return Scaffold(
      floatingActionButton: widget.floatingActionButton,
      body: Stack(
        children: [
          if (widget.background != null) ...[
            Positioned.fill(child: widget.background!),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX:
                      designTokens.blurShadow *
                      componentTokens.backgroundBlurScale,
                  sigmaY:
                      designTokens.blurShadow *
                      componentTokens.backgroundBlurScale,
                ),
                child: ColoredBox(
                  color: theme.colorScheme.surface.withValues(
                    alpha: componentTokens.backgroundOverlayOpacity,
                  ),
                ),
              ),
            ),
          ],
          // Full-bleed content layer. Isolated in its own RepaintBoundary
          // so overlay fade/slide never invalidates the preview.
          Positioned.fill(
            child: RepaintBoundary(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) => _handleInteraction(),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _handleTap,
                  child: widget.preview,
                ),
              ),
            ),
          ),
          // Top overlay.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _OverlaySlot(
              isTopPanel: true,
              visible: _visible,
              duration: _animationDuration,
              slideFrom: const Offset(0, -1),
              child: SafeArea(
                bottom: false,
                child: _TopAppBar(
                  title: widget.title,
                  leading: widget.leading,
                  trailing: widget.trailing,
                  onClose: widget.onClose,
                ),
              ),
            ),
          ),
          // Bottom overlay.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _OverlaySlot(
              isTopPanel: false,
              visible: _visible,
              duration: _animationDuration,
              slideFrom: const Offset(0, 1),
              child: _BottomPanel(
                onInteraction: _handleInteraction,
                child: widget.bottomPanel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlaySlot extends StatelessWidget {
  const _OverlaySlot({
    required this.visible,
    required this.duration,
    required this.slideFrom,
    required this.child,
    required this.isTopPanel,
  });

  final bool visible;
  final Duration duration;
  final Offset slideFrom;
  final Widget child;
  final bool isTopPanel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designTokens = theme.tokens;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        duration: duration,
        curve: Curves.easeOut,
        offset: visible ? Offset.zero : slideFrom,
        child: AnimatedOpacity(
          duration: duration,
          curve: Curves.easeOut,
          opacity: visible ? 1 : 0,
          child: RepaintBoundary(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: designTokens.blurGlass,
                  sigmaY: designTokens.blurGlass,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    // color: theme.colorScheme.surface,
                    color: Colors.green,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(isTopPanel ? 16 : 0),
                      top: Radius.circular(isTopPanel ? 0 : 16),
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({
    required this.title,
    required this.leading,
    required this.trailing,
    required this.onClose,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.immersiveComposer;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: designTokens.spaceLarge,
        vertical: designTokens.spaceSmall,
      ),
      child: Row(
        children: [
          leading ??
              _RoundHeaderButton(icon: Icons.close_rounded, onPressed: onClose),
          Expanded(child: Text(title, textAlign: TextAlign.center)),
          trailing ??
              SizedBox(
                width: componentTokens.headerButtonSize,
                height: componentTokens.headerButtonSize,
              ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.onInteraction, required this.child});

  final VoidCallback onInteraction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) => onInteraction(),
      onPointerMove: (_) => onInteraction(),
      child: child,
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
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.immersiveComposer;

    return Container(
      width: componentTokens.headerButtonSize,
      height: componentTokens.headerButtonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surface.withValues(
          alpha: designTokens.opacityGlass,
        ),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(
            alpha: designTokens.opacitySubtle,
          ),
          width: designTokens.borderWidthThin,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size:
              designTokens.iconSizeMedium +
              componentTokens.headerIconSizeOffset,
        ),
      ),
    );
  }
}
