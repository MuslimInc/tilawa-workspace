import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Ensure Google Fonts doesn't try to fetch anything during tests
  GoogleFonts.config.allowRuntimeFetching = false;

  // Stable metrics for [GoldenTestScenario] titles (Alchemist) — avoids ±1–2px
  // total golden height drift across Flutter / font versions vs committed PNGs.
  final GoldenTestTheme standard = GoldenTestTheme.standard();
  final GoldenTestTheme goldenTestTheme = GoldenTestTheme(
    backgroundColor: standard.backgroundColor,
    borderColor: standard.borderColor,
    nameTextStyle: const TextStyle(
      fontSize: 18,
      height: 1.0,
      fontFamily: 'Roboto',
    ),
    padding: standard.padding,
  );

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: const PlatformGoldensConfig(enabled: true),
      ciGoldensConfig: const CiGoldensConfig(enabled: false),
      goldenTestTheme: goldenTestTheme,
    ),
    run: testMain,
  );
}
