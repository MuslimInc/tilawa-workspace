import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Alchemist setup for ui_kit_v2 goldens.
///
/// Mirrors the conventions in `packages/ui_kit/test/flutter_test_config.dart`:
/// disables runtime font fetching, pins the scenario caption strut, and
/// enables `platformGoldens` (macOS PNGs) while keeping `ciGoldens` off
/// (we don't run goldens in CI yet).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;

  final standard = GoldenTestTheme.standard();
  final theme = GoldenTestTheme(
    backgroundColor: standard.backgroundColor,
    borderColor: standard.borderColor,
    nameTextStyle: const TextStyle(
      fontSize: 14,
      height: 1.0,
      fontFamily: 'Roboto',
    ),
    padding: standard.padding,
  );

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: const PlatformGoldensConfig(enabled: true),
      ciGoldensConfig: const CiGoldensConfig(enabled: false),
      goldenTestTheme: theme,
    ),
    run: testMain,
  );
}
