import 'package:flutter/material.dart';

/// An inherited widget that provides the bottom padding needed to clear
/// the adaptive shell's navigation bar and player.
class TilawaShellPadding extends InheritedWidget {
  const TilawaShellPadding({
    super.key,
    required this.padding,
    required super.child,
  });

  final double padding;

  static double of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<TilawaShellPadding>();
    return result?.padding ?? 0;
  }

  @override
  bool updateShouldNotify(TilawaShellPadding oldWidget) {
    return oldWidget.padding != padding;
  }
}
