import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Ensure Google Fonts doesn't try to fetch anything during tests
  GoogleFonts.config.allowRuntimeFetching = false;

  // Strictly disable Google Fonts in the AppTheme for the test environment
  AppTheme.useGoogleFonts = false;

  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: true),
    ),
    run: testMain,
  );
}
