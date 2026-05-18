import 'package:flutter/material.dart';

import '../foundation/foundation.dart';
import 'tilawa_spinner.dart';

/// Button variants — mirror the four `.tw-btn--*` flavors in mobile.css.
enum TilawaBtnVariant {
  /// Solid emerald with a tinted glow. The CTA of the brand.
  primary,

  /// Soft brand-tinted background, brand-dark text. Calmer than primary.
  ghost,

  /// Transparent, brand-tinted on hover. For low-emphasis actions.
  quiet,

  /// Translucent white over a dark surface. Used inside hero cards.
  inverse,
}

enum TilawaBtnSize {
  sm,
  md,
}

/// The base button atom. Honours min tap target ([TilawaSpacing.tapMin]) and
/// supports loading / disabled state.
class TilawaBtn extends StatefulWidget {
  const TilawaBtn({
    required this.label,
    required this.onPressed,
    this.variant = TilawaBtnVariant.primary,
    this.size = TilawaBtnSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final TilawaBtnVariant variant;
  final TilawaBtnSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool expand;

  @override
  State<TilawaBtn> createState() => _TilawaBtnState();
}

class _TilawaBtnState extends State<TilawaBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final colors = theme.tokens.colors;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    final styling = _stylingFor(widget.variant, colors);
    final textStyle = theme.typography.button.copyWith(color: styling.fg);

    final minHeight = widget.size == TilawaBtnSize.sm
        ? 36.0
        : TilawaSpacing.tapMin;
    final hPad = widget.size == TilawaBtnSize.sm ? 14.0 : 20.0;
    final vPad = widget.size == TilawaBtnSize.sm ? 8.0 : 12.0;

    final content = widget.isLoading
        ? TilawaSpinner(color: styling.fg, size: 18)
        : _buildContent(textStyle, styling.fg);

    final scale = _pressed && !isDisabled ? 0.97 : 1.0;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1,
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapCancel: isDisabled ? null : () => setState(() => _pressed = false),
        onTapUp: isDisabled ? null : (_) => setState(() => _pressed = false),
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: scale,
          duration: TilawaMotion.fast,
          curve: TilawaMotion.standard,
          child: AnimatedContainer(
            duration: TilawaMotion.base,
            curve: TilawaMotion.standard,
            constraints: BoxConstraints(
              minHeight: minHeight,
              minWidth: widget.expand ? double.infinity : 0,
            ),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              color: styling.bg,
              borderRadius: TilawaRadii.brMd,
              boxShadow: styling.shadow,
            ),
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [content],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(TextStyle textStyle, Color fg) {
    final children = <Widget>[
      if (widget.leadingIcon != null) ...[
        Icon(widget.leadingIcon, size: 18, color: fg),
        const SizedBox(width: 8),
      ],
      Flexible(
        child: Text(
          widget.label,
          style: textStyle,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      if (widget.trailingIcon != null) ...[
        const SizedBox(width: 8),
        Icon(widget.trailingIcon, size: 18, color: fg),
      ],
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  _BtnStyling _stylingFor(TilawaBtnVariant variant, TilawaColors c) {
    switch (variant) {
      case TilawaBtnVariant.primary:
        return _BtnStyling(
          bg: _pressed ? TilawaPalette.green700 : c.brand,
          fg: c.fgOnPrimary,
          shadow: TilawaShadows.glow,
        );
      case TilawaBtnVariant.ghost:
        return _BtnStyling(
          bg: _pressed
              ? const Color(0x1A2D5C3F) // ~0.10
              : c.brandSoft, // ~0.06
          fg: TilawaPalette.green700,
        );
      case TilawaBtnVariant.quiet:
        return _BtnStyling(
          bg: _pressed
              ? const Color(0x0D2D5C3F) // ~0.05
              : Colors.transparent,
          fg: c.brand,
        );
      case TilawaBtnVariant.inverse:
        return _BtnStyling(
          bg: _pressed
              ? const Color(0x42FFFFFF) // ~0.26
              : const Color(0x2EFFFFFF), // ~0.18
          fg: c.fgOnPrimary,
        );
    }
  }
}

class _BtnStyling {
  _BtnStyling({required this.bg, required this.fg, this.shadow});

  final Color bg;
  final Color fg;
  final List<BoxShadow>? shadow;
}
