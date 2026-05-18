import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit_v2/tilawa_ui_kit_v2.dart';

/// Wraps a widget in the design-system theme + a fixed light surface so
/// goldens render deterministically.
class V2PreviewWrapper extends StatelessWidget {
  const V2PreviewWrapper({
    required this.child,
    this.background,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final Color? background;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return TilawaTheme.light(
      child: Builder(
        builder: (context) {
          final tokens = TilawaTheme.of(context).tokens.colors;
          return Material(
            color: background ?? tokens.bgPage,
            child: Padding(padding: padding, child: child),
          );
        },
      ),
    );
  }
}

/// A standard frame to render mobile-first components in: 360x???.
/// We use 360 as the design system base width — matches the mobile UI kit's
/// reference frame.
class V2MobileFrame extends StatelessWidget {
  const V2MobileFrame({
    required this.child,
    this.height,
    super.key,
  });

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: height,
      child: V2PreviewWrapper(
        padding: EdgeInsets.zero,
        background: const Color(0xFFFAFBFC),
        child: child,
      ),
    );
  }
}
