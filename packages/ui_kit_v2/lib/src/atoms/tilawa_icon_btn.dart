import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

enum TilawaIconBtnVariant {
  plain,
  ring,
  solid,
  inverse,
}

enum TilawaIconBtnSize {
  md,
  lg,
}

/// 40×40 (or 64×64) icon-only button. Matches `.tw-iconbtn`.
class TilawaIconBtn extends StatefulWidget {
  const TilawaIconBtn({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.variant = TilawaIconBtnVariant.plain,
    this.size = TilawaIconBtnSize.md,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final TilawaIconBtnVariant variant;
  final TilawaIconBtnSize size;

  @override
  State<TilawaIconBtn> createState() => _TilawaIconBtnState();
}

class _TilawaIconBtnState extends State<TilawaIconBtn> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = TilawaTheme.of(context).tokens.colors;
    final disabled = widget.onPressed == null;
    final dim = widget.size == TilawaIconBtnSize.lg ? 64.0 : 40.0;
    final iconSize = widget.size == TilawaIconBtnSize.lg ? 30.0 : 20.0;

    final styling = _stylingFor(widget.variant, colors);
    final scale = _pressed && !disabled ? 0.92 : 1.0;

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: !disabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: disabled
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
          onTapCancel: disabled ? null : () => setState(() => _pressed = false),
          onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
          onTap: disabled ? null : widget.onPressed,
          child: AnimatedScale(
            scale: scale,
            duration: TilawaMotion.fast,
            curve: TilawaMotion.standard,
            child: AnimatedContainer(
              duration: TilawaMotion.fast,
              curve: TilawaMotion.standard,
              width: dim,
              height: dim,
              decoration: BoxDecoration(
                color: styling.bg,
                shape: BoxShape.circle,
                border: styling.border,
                boxShadow: styling.shadow,
              ),
              child: Center(
                child: Icon(widget.icon, size: iconSize, color: styling.fg),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _IconBtnStyling _stylingFor(TilawaIconBtnVariant v, TilawaColors c) {
    switch (v) {
      case TilawaIconBtnVariant.plain:
        return _IconBtnStyling(
          bg: _hovered ? const Color(0x0A0F172A) : Colors.transparent,
          fg: c.fg1,
        );
      case TilawaIconBtnVariant.ring:
        return _IconBtnStyling(
          bg: c.bgCard,
          fg: c.fg1,
          border: Border.all(
            color: _hovered
                ? const Color(0x1F0F172A)
                : c.hairline,
          ),
          shadow: TilawaShadows.el1,
        );
      case TilawaIconBtnVariant.solid:
        return _IconBtnStyling(
          bg: _hovered ? TilawaPalette.green700 : c.brand,
          fg: c.fgOnPrimary,
          shadow: TilawaShadows.glow,
        );
      case TilawaIconBtnVariant.inverse:
        return _IconBtnStyling(
          bg: _hovered
              ? const Color(0x1AFFFFFF)
              : Colors.transparent,
          fg: c.fgOnPrimary,
        );
    }
  }
}

class _IconBtnStyling {
  _IconBtnStyling({
    required this.bg,
    required this.fg,
    this.border,
    this.shadow,
  });

  final Color bg;
  final Color fg;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;
}
