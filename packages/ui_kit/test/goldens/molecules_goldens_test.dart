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
      'MetadataChip',
      fileName: 'tilawa_metadata_chip',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default icon + label',
            child: const TilawaPreviewWrapper(
              child: MetadataChip(
                label: '604 pages',
                icon: Icons.menu_book_rounded,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Label only',
            child: const TilawaPreviewWrapper(
              child: MetadataChip(label: '604 pages'),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark',
            child: const TilawaPreviewWrapper(
              isDark: true,
              child: MetadataChip(
                label: '604 pages',
                icon: Icons.menu_book_rounded,
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'SelectionPill',
      fileName: 'tilawa_selection_pill',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Selected',
            child: TilawaPreviewWrapper(
              child: SelectionPill(label: 'All', selected: true, onTap: () {}),
            ),
          ),
          GoldenTestScenario(
            name: 'Unselected with icon',
            child: TilawaPreviewWrapper(
              child: SelectionPill(
                label: 'Recent',
                selected: false,
                icon: Icons.history,
                onTap: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark selected',
            child: TilawaPreviewWrapper(
              isDark: true,
              child: SelectionPill(label: 'All', selected: true, onTap: () {}),
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

    goldenTest(
      'TilawaFeedbackStrip',
      fileName: 'tilawa_feedback_strip',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default',
            child: TilawaPreviewWrapper(
              child: Builder(
                builder: (context) {
                  final scheme = Theme.of(context).colorScheme;
                  return TilawaFeedbackStrip(
                    icon: Icons.check_circle_rounded,
                    message: 'Saved successfully',
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                  );
                },
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark',
            child: TilawaPreviewWrapper(
              isDark: true,
              child: Builder(
                builder: (context) {
                  final scheme = Theme.of(context).colorScheme;
                  return TilawaFeedbackStrip(
                    icon: Icons.check_circle_rounded,
                    message: 'Saved successfully',
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                  );
                },
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'RTL Arabic',
            child: TilawaPreviewWrapper(
              isRTL: true,
              child: Builder(
                builder: (context) {
                  final scheme = Theme.of(context).colorScheme;
                  return TilawaFeedbackStrip(
                    icon: Icons.check_circle_rounded,
                    message: 'تم الحفظ بنجاح',
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaPermissionBanner',
      fileName: 'tilawa_permission_banner',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default',
            child: TilawaPreviewWrapper(
              child: TilawaPermissionBanner(
                message: 'Enable notifications to receive prayer alerts',
                actionLabel: 'Enable',
                onAction: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark',
            child: TilawaPreviewWrapper(
              isDark: true,
              child: TilawaPermissionBanner(
                message: 'Enable notifications to receive prayer alerts',
                actionLabel: 'Enable',
                onAction: () {},
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'LanguageSwitcher',
      fileName: 'tilawa_language_switcher',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'English selected',
            child: TilawaPreviewWrapper(
              child: LanguageSwitcher(
                currentLanguage: 'en',
                languages: const ['en', 'ar'],
                getLanguageName: (code) => code == 'en' ? 'English' : 'العربية',
                onLanguageChanged: (_) {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Arabic selected',
            child: TilawaPreviewWrapper(
              child: LanguageSwitcher(
                currentLanguage: 'ar',
                languages: const ['en', 'ar'],
                getLanguageName: (code) => code == 'en' ? 'English' : 'العربية',
                onLanguageChanged: (_) {},
              ),
            ),
          ),
        ],
      ),
    );
  });
}
