import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/molecules/molecules.dart';

import '../../lib/src/previews/preview_wrapper.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  AppTheme.useGoogleFonts = false;

  group('Molecules Golden Tests', () {
    goldenTest(
      'TilawaGlassPanel',
      fileName: 'tilawa_glass_panel',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light',
            child: const TilawaPreviewWrapper(
              child: TilawaGlassPanel(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Glass Panel'),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark',
            child: const TilawaPreviewWrapper(
              isDark: true,
              child: TilawaGlassPanel(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Dark Glass Panel'),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaStatusChip',
      fileName: 'tilawa_status_chip',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Success',
            child: const TilawaPreviewWrapper(
              child: TilawaStatusChip(label: 'Success'),
            ),
          ),
          GoldenTestScenario(
            name: 'Warning',
            child: const TilawaPreviewWrapper(
              child: TilawaStatusChip(label: 'Warning'),
            ),
          ),
          GoldenTestScenario(
            name: 'Error',
            child: const TilawaPreviewWrapper(
              child: TilawaStatusChip(label: 'Error'),
            ),
          ),
          GoldenTestScenario(
            name: 'RTL',
            child: const TilawaPreviewWrapper(
              isRTL: true,
              child: TilawaStatusChip(label: 'ناجح'),
            ),
          ),
        ],
      ),
    );
  });
}
