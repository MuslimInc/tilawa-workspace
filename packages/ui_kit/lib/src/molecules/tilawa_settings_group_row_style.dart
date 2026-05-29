import 'package:flutter/material.dart';

/// Supplies per-row corner radii for ink effects inside [TilawaSettingsGroupPanel].
class TilawaSettingsGroupRowStyle extends InheritedWidget {
  const TilawaSettingsGroupRowStyle({
    super.key,
    required this.borderRadius,
    required super.child,
  });

  final BorderRadius borderRadius;

  static TilawaSettingsGroupRowStyle? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TilawaSettingsGroupRowStyle>();
  }

  @override
  bool updateShouldNotify(TilawaSettingsGroupRowStyle oldWidget) {
    return borderRadius != oldWidget.borderRadius;
  }
}

/// Corner radii for the first/last row ink splash inside a settings group.
BorderRadius tilawaSettingsGroupRowBorderRadius({
  required int index,
  required int rowCount,
  required double radius,
}) {
  if (rowCount <= 0) {
    return BorderRadius.zero;
  }
  if (rowCount == 1) {
    return BorderRadius.circular(radius);
  }
  if (index == 0) {
    return BorderRadius.vertical(top: Radius.circular(radius));
  }
  if (index == rowCount - 1) {
    return BorderRadius.vertical(bottom: Radius.circular(radius));
  }
  return BorderRadius.zero;
}
