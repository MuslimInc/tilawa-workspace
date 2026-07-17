import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Trailing gap below the last Home dashboard block.
///
/// [TilawaAdaptiveShell] lays the tab body above the bottom navigation bar
/// and mini-player column, so scroll padding must not add shell chrome again.
/// Extra large keeps the last card fully clear of the fold when settling.
double homeDashboardScrollBottomPadding(BuildContext context) {
  return context.tokens.spaceExtraLarge;
}
