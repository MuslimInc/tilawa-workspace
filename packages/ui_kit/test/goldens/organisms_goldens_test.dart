import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../lib/src/previews/preview_wrapper.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  AppTheme.useGoogleFonts = false;

  group('Organisms Golden Tests', () {
    goldenTest(
      'TilawaMediaPlayerBar',
      fileName: 'organisms/tilawa_media_player_bar',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Playing default',
            child: const TilawaPreviewWrapper(
              child: SizedBox(
                width: 360,
                child: TilawaMediaPlayerBar(
                  title: 'Surah Al-Fatiha',
                  subtitle: 'Abdul Basit',
                  progress: 0.4,
                  isPlaying: true,
                  canGoPrevious: true,
                  canGoNext: true,
                  isSleepTimerActive: false,
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Paused disabled nav',
            child: const TilawaPreviewWrapper(
              child: SizedBox(
                width: 360,
                child: TilawaMediaPlayerBar(
                  title: 'Surah Al-Fatiha',
                  subtitle: 'Abdul Basit',
                  progress: 0.0,
                  isPlaying: false,
                  canGoPrevious: false,
                  canGoNext: false,
                  isSleepTimerActive: false,
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Sleep timer active',
            child: const TilawaPreviewWrapper(
              child: SizedBox(
                width: 360,
                child: TilawaMediaPlayerBar(
                  title: 'Surah Al-Fatiha',
                  subtitle: 'Abdul Basit',
                  progress: 0.6,
                  isPlaying: true,
                  canGoPrevious: true,
                  canGoNext: true,
                  isSleepTimerActive: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );

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
                      onTap: () {},
                    ),
                    TilawaSettingsSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark mode',
                      value: false,
                      onChanged: (_) {},
                    ),
                    TilawaSettingsTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: () {},
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
                      onTap: () {},
                    ),
                    TilawaSettingsSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark mode',
                      value: false,
                      onChanged: (_) {},
                    ),
                    TilawaSettingsTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: () {},
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

    goldenTest(
      'TilawaSettingsGroup compact',
      fileName: 'organisms/tilawa_settings_group_compact',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default (compact)',
            child: TilawaPreviewWrapper(
              density: TilawaDensity.compact,
              child: SizedBox(
                width: 340,
                child: TilawaSettingsGroup(
                  title: 'Preferences',
                  children: [
                    TilawaSettingsTile(
                      icon: Icons.language,
                      title: 'Language',
                      onTap: () {},
                    ),
                    TilawaSettingsSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark mode',
                      value: false,
                      onChanged: (_) {},
                    ),
                    TilawaSettingsTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: () {},
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark (compact)',
            child: TilawaPreviewWrapper(
              isDark: true,
              density: TilawaDensity.compact,
              child: SizedBox(
                width: 340,
                child: TilawaSettingsGroup(
                  title: 'Preferences',
                  children: [
                    TilawaSettingsTile(
                      icon: Icons.language,
                      title: 'Language',
                      onTap: () {},
                    ),
                    TilawaSettingsSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark mode',
                      value: false,
                      onChanged: (_) {},
                    ),
                    TilawaSettingsTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: () {},
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

    goldenTest(
      'TilawaShareFooterBar',
      fileName: 'organisms/tilawa_share_footer_bar',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 360,
                child: TilawaShareFooterBar(
                  primaryLabel: 'Surah Al-Fatiha',
                  secondaryLabel: 'Abdul Basit',
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark',
            child: TilawaPreviewWrapper(
              isDark: true,
              child: SizedBox(
                width: 360,
                child: TilawaShareFooterBar(
                  primaryLabel: 'Surah Al-Fatiha',
                  secondaryLabel: 'Abdul Basit',
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaShareFooterBar compact',
      fileName: 'organisms/tilawa_share_footer_bar_compact',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default (compact)',
            child: TilawaPreviewWrapper(
              density: TilawaDensity.compact,
              child: SizedBox(
                width: 360,
                child: TilawaShareFooterBar(
                  primaryLabel: 'Surah Al-Fatiha',
                  secondaryLabel: 'Abdul Basit',
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark (compact)',
            child: TilawaPreviewWrapper(
              density: TilawaDensity.compact,
              isDark: true,
              child: SizedBox(
                width: 360,
                child: TilawaShareFooterBar(
                  primaryLabel: 'Surah Al-Fatiha',
                  secondaryLabel: 'Abdul Basit',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
