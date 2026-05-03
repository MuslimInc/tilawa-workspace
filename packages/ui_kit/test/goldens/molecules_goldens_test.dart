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
          GoldenTestScenario(
            name: 'Dark',
            child: const TilawaPreviewWrapper(
              isDark: true,
              child: TilawaStatusChip(label: 'Live'),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaChip',
      fileName: 'tilawa_chip',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default',
            child: const TilawaPreviewWrapper(
              child: TilawaChip(label: 'Bookmarked', icon: Icons.bookmark),
            ),
          ),
          GoldenTestScenario(
            name: 'Label only',
            child: const TilawaPreviewWrapper(
              child: TilawaChip(label: 'Favorite'),
            ),
          ),
          GoldenTestScenario(
            name: 'Selected style',
            child: const TilawaPreviewWrapper(
              child: TilawaChip(
                label: 'Selected',
                icon: Icons.check,
                showShadow: true,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'RTL Arabic',
            child: const TilawaPreviewWrapper(
              isRTL: true,
              child: TilawaChip(label: 'محفوظ', icon: Icons.bookmark),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaIconActionButton',
      fileName: 'tilawa_icon_action_button',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Inactive',
            child: TilawaPreviewWrapper(
              child: TilawaIconActionButton(
                icon: Icons.favorite_border,
                onTap: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Active',
            child: TilawaPreviewWrapper(
              child: TilawaIconActionButton(
                icon: Icons.favorite,
                isActive: true,
                onTap: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark',
            child: TilawaPreviewWrapper(
              isDark: true,
              child: TilawaIconActionButton(
                icon: Icons.favorite_border,
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSearchField',
      fileName: 'tilawa_search_field',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default',
            child: TilawaPreviewWrapper(
              child: TilawaSearchField(
                hintText: 'Search surahs',
                onChanged: (_) {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'With text',
            child: Builder(
              builder: (context) {
                final controller = TextEditingController(text: 'Al-Baqarah');
                return TilawaPreviewWrapper(
                  child: TilawaSearchField(
                    hintText: 'Search surahs',
                    controller: controller,
                    onChanged: (_) {},
                    onClear: controller.clear,
                  ),
                );
              },
            ),
          ),
          GoldenTestScenario(
            name: 'Disabled',
            child: TilawaPreviewWrapper(
              child: TilawaSearchField(
                hintText: 'Search surahs',
                enabled: false,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'RTL Arabic',
            child: Builder(
              builder: (context) {
                final controller = TextEditingController(text: 'الفاتحة');
                return TilawaPreviewWrapper(
                  isRTL: true,
                  child: TilawaSearchField(
                    hintText: 'ابحث في السور',
                    controller: controller,
                    onChanged: (_) {},
                    onClear: controller.clear,
                  ),
                );
              },
            ),
          ),
          GoldenTestScenario(
            name: 'Dark',
            child: TilawaPreviewWrapper(
              isDark: true,
              child: TilawaSearchField(
                hintText: 'Search surahs',
                onChanged: (_) {},
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSettingsTiles',
      fileName: 'tilawa_settings_tile',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Tile with subtitle',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 340,
                child: TilawaSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Daily prayer alerts',
                  onTap: () {},
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Tile no subtitle',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 340,
                child: TilawaSettingsTile(
                  icon: Icons.language,
                  title: 'Language',
                  onTap: () {},
                  showDivider: false,
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Switch off',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 340,
                child: TilawaSettingsSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark mode',
                  value: false,
                  onChanged: (_) {},
                  showDivider: false,
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Switch on',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 340,
                child: TilawaSettingsSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark mode',
                  value: true,
                  onChanged: (_) {},
                  showDivider: false,
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'RTL Arabic',
            child: TilawaPreviewWrapper(
              isRTL: true,
              child: SizedBox(
                width: 340,
                child: TilawaSettingsSwitchTile(
                  icon: Icons.notifications_outlined,
                  title: 'إشعارات الصلاة',
                  subtitle: 'تشغيل التنبيهات',
                  value: true,
                  onChanged: (_) {},
                  showDivider: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
