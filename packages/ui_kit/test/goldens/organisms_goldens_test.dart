import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/molecules/molecules.dart';
import 'package:tilawa_ui_kit/src/organisms/organisms.dart';

import '../../lib/src/previews/preview_wrapper.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  AppTheme.useGoogleFonts = false;

  group('Organisms Golden Tests', () {
    goldenTest(
      'TilawaSettingsGroup',
      fileName: 'organisms/tilawa_settings_group',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 340,
                child: TilawaSettingsGroup(
                  title: 'Preferences',
                  children: [
                    TilawaSettingsTile(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'English',
                      onTap: () {},
                    ),
                    TilawaSettingsSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark mode',
                      value: false,
                      onChanged: (_) {},
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark',
            child: TilawaPreviewWrapper(
              isDark: true,
              child: SizedBox(
                width: 340,
                child: TilawaSettingsGroup(
                  title: 'Preferences',
                  children: [
                    TilawaSettingsTile(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'English',
                      onTap: () {},
                    ),
                    TilawaSettingsSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark mode',
                      value: false,
                      onChanged: (_) {},
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
