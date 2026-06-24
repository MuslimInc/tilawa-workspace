import 'package:flutter/material.dart';

import 'component_tokens.dart';
import 'content_bounds.dart';
import 'design_tokens.dart';
import 'safe_area_ext.dart';
import 'tilawa_comfortable_reach_padding.dart';

/// Sticky full-screen footer chrome for primary bottom actions.
///
/// Mirrors [TilawaBottomSheetScaffold]'s footer band (surface, top border,
/// comfortable bottom spacing) for [Scaffold] bodies. Pair with
/// [TilawaFormScreenScaffold] or place at the bottom of a [Column].
class TilawaBottomActionArea extends StatefulWidget {
  /// Creates a sticky bottom action band.
  const TilawaBottomActionArea({
    super.key,
    required this.child,
    this.top = 0,
    this.horizontal,
    this.extraBottom = 0,
    this.keyboardAware = true,
    this.showTopBorder = true,
    this.maxWidthKind,
  });

  /// Primary controls (buttons, indicators, footer chrome).
  final Widget child;

  /// Space above [child] inside the padded region.
  final double top;

  /// Horizontal inset; defaults to [TilawaDesignTokens.bottomActionHorizontalInset].
  final double? horizontal;

  /// Additional bottom clearance (shell nav, mini-player, FAB stack).
  final double extraBottom;

  /// When true, lifts content above the software keyboard.
  final bool keyboardAware;

  /// When true, draws the same top divider as sheet footers.
  final bool showTopBorder;

  /// When set, constrains [child] via [TilawaContentBounds.resolveMaxWidth].
  final TilawaContentKind? maxWidthKind;

  @override
  State<TilawaBottomActionArea> createState() => _TilawaBottomActionAreaState();
}

class _TilawaBottomActionAreaState extends State<TilawaBottomActionArea> {
  static const Duration _paddingAnimationDuration = Duration(milliseconds: 250);

  double _maxKeyboardInset = 0;
  bool _keyboardWasVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _onKeyboardInsetChanged(context.effectiveKeyboardInset);
  }

  void _onKeyboardInsetChanged(double inset) {
    final bool isVisible = inset > 0;

    if (isVisible) {
      if (inset > _maxKeyboardInset) {
        _maxKeyboardInset = inset;
      }
      _keyboardWasVisible = true;
      return;
    }

    if (_keyboardWasVisible) {
      _keyboardWasVisible = false;
      _schedulePostDismissRefresh();
    }
  }

  void _schedulePostDismissRefresh() {
    Future<void>.delayed(_paddingAnimationDuration, () {
      if (!mounted) {
        return;
      }
      if (context.effectiveKeyboardInset > 0) {
        return;
      }
      setState(() {
        _maxKeyboardInset = 0;
      });
    });
  }

  double _resolveClosedComfortable(BuildContext context) {
    return TilawaComfortableReachPadding.resolveClosed(
      context,
      kind: TilawaComfortableReachKind.screen,
    );
  }

  double _resolveComfortableTarget(BuildContext context) {
    final double inset = context.effectiveKeyboardInset;

    if (widget.keyboardAware && inset > 0) {
      return TilawaComfortableReachPadding.resolve(
        context,
        kind: TilawaComfortableReachKind.screen,
        keyboardAware: true,
      );
    }

    if (!widget.keyboardAware && inset > 0) {
      return TilawaComfortableReachPadding.resolveKeyboardOpen(context);
    }

    return _resolveClosedComfortable(context);
  }

  double _resolveBottomPadding(BuildContext context) {
    return _resolveComfortableTarget(context) + widget.extraBottom;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final TilawaBottomSheetScaffoldTokens sheetTokens =
        theme.componentTokens.bottomSheetScaffold;
    final TextDirection direction = Directionality.of(context);
    final EdgeInsets footerPadding = sheetTokens.footerPadding.resolve(
      direction,
    );
    final double side = widget.horizontal ?? tokens.bottomActionHorizontalInset;
    final double bottom = _resolveBottomPadding(context);

    Widget content = widget.child;
    if (widget.maxWidthKind != null) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: TilawaContentBounds.resolveMaxWidth(
              context,
              widget.maxWidthKind!,
            ),
          ),
          child: content,
        ),
      );
    }

    // [Column] with [MainAxisSize.min] prevents [Material] from expanding to
    // fill [Scaffold.bottomNavigationBar]'s loose max-height constraint.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: theme.colorScheme.surface,
          child: DecoratedBox(
            decoration: widget.showTopBorder
                ? BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                        width: sheetTokens.footerTopBorderWidth,
                      ),
                    ),
                  )
                : const BoxDecoration(),
            child: SafeArea(
              top: false,
              bottom: false,
              child: AnimatedPadding(
                duration: _paddingAnimationDuration,
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                  side,
                  widget.top + footerPadding.top,
                  side,
                  bottom,
                ),
                child: content,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
