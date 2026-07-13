import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Trailing gap below the last Home dashboard block (~16 dp).
///
/// [TilawaAdaptiveShell] lays the tab body above the bottom navigation bar
/// and mini-player column, so scroll padding must not add shell chrome again.
double homeDashboardScrollBottomPadding(BuildContext context) {
  return context.tokens.spaceLarge;
}
