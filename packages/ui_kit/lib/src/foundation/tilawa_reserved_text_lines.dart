import 'package:flutter/material.dart';

/// Fixed-height text slot so locale / length changes do not shift siblings.
///
/// Height = `textScaler.scale(fontSize) × height × maxLines` with strut forced
/// to match, and the label vertically centered inside the slot.
class TilawaReservedTextLines extends StatelessWidget {
  /// Creates a reserved multi-line text slot.
  const TilawaReservedTextLines({
    super.key,
    required this.text,
    required this.style,
    required this.maxLines,
    this.textAlign = TextAlign.center,
    this.overflow = TextOverflow.ellipsis,
    this.alignment = Alignment.center,
  });

  /// Visible copy.
  final String text;

  /// Typographic style; [TextStyle.fontSize] / [TextStyle.height] drive the slot.
  final TextStyle style;

  /// Lines reserved (and painted at most).
  final int maxLines;

  /// Text alignment inside the slot.
  final TextAlign textAlign;

  /// Overflow when copy exceeds [maxLines].
  final TextOverflow overflow;

  /// Child alignment within the fixed-height box.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final double fontSize = style.fontSize ?? 14;
    final double heightFactor = style.height ?? 1.2;
    final TextStyle resolved = style.copyWith(
      fontSize: fontSize,
      height: heightFactor,
    );
    final double slotHeight =
        MediaQuery.textScalerOf(context).scale(fontSize) *
        heightFactor *
        maxLines;

    return SizedBox(
      height: slotHeight,
      width: double.infinity,
      child: Align(
        alignment: alignment,
        child: Text(
          text,
          style: resolved,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          strutStyle: StrutStyle.fromTextStyle(
            resolved,
            forceStrutHeight: true,
          ),
        ),
      ),
    );
  }
}
