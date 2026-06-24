import 'package:flutter/material.dart';

/// Thumb-reach side for [TilawaPrimaryFab] inside a [Scaffold].
enum TilawaFabPlacement {
  /// Bottom-start (MoneyLoop-style left on LTR). Preferred for one-handed reach.
  start,

  /// Bottom-end (Material default on LTR).
  end,
}

/// Resolves [FloatingActionButtonLocation] with optional bottom inset.
///
/// Use [bottomOffset] to clear the shell bottom nav and mini-player chrome
/// (e.g. `QuranPlayerWidget.fabBottomOffset(context) + tokens.spaceLarge`).
final class TilawaFabLocation {
  const TilawaFabLocation._();

  /// Returns a [FloatingActionButtonLocation] for [placement].
  static FloatingActionButtonLocation placement(
    TilawaFabPlacement placement, {
    double bottomOffset = 0,
  }) {
    final FloatingActionButtonLocation base = switch (placement) {
      TilawaFabPlacement.start => FloatingActionButtonLocation.startFloat,
      TilawaFabPlacement.end => FloatingActionButtonLocation.endFloat,
    };
    if (bottomOffset == 0) {
      return base;
    }
    return _TilawaOffsetFabLocation(
      base: base,
      bottomOffset: bottomOffset,
    );
  }
}

class _TilawaOffsetFabLocation extends FloatingActionButtonLocation {
  const _TilawaOffsetFabLocation({
    required this.base,
    required this.bottomOffset,
  });

  final FloatingActionButtonLocation base;
  final double bottomOffset;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final Offset resolved = base.getOffset(scaffoldGeometry);
    final double y =
        scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        bottomOffset;
    return Offset(resolved.dx, y);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _TilawaOffsetFabLocation &&
        other.base == base &&
        other.bottomOffset == bottomOffset;
  }

  @override
  int get hashCode => Object.hash(base, bottomOffset);

  @override
  String toString() => 'TilawaFabLocation(offset: $bottomOffset)';
}
