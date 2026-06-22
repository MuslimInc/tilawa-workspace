import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/molecules/molecules.dart';

import '../../lib/src/previews/preview_wrapper.dart';
import 'golden_constraints.dart';

/// Stable line box for glass-panel golden body text (reduces ±1px vertical
/// drift between Flutter / font versions).
const StrutStyle _kGoldenGlassPanelBodyStrut = StrutStyle(
  fontSize: 16,
  height: 1.25,
  forceStrutHeight: true,
);

void main() {
  group('Molecules Golden Tests', () {
    goldenTest(
      'TilawaGlassPanel',
      fileName: 'molecules/tilawa_glass_panel',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: [
          GoldenTestScenario(
            name: 'Light',
            child: const TilawaPreviewWrapper(
              child: TilawaGlassPanel(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Glass Panel',
                    strutStyle: _kGoldenGlassPanelBodyStrut,
                  ),
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
                  child: Text(
                    'Dark Glass Panel',
                    strutStyle: _kGoldenGlassPanelBodyStrut,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaStatusChip',
      fileName: 'molecules/tilawa_status_chip',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
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
      fileName: 'molecules/tilawa_chip',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
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
      'TilawaChip constrained columns',
      fileName: 'molecules/tilawa_chip_constrained',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(
          minWidth: 360,
          maxWidth: 360,
          minHeight: 72,
          maxHeight: 72,
        ),
        children: [
          GoldenTestScenario(
            name: 'Override type row light',
            child: TilawaPreviewWrapper(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TilawaChip(
                        label: 'Unavailable (day off)',
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TilawaChip(
                        label: 'Custom hours',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Override type row dark',
            child: TilawaPreviewWrapper(
              isDark: true,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TilawaChip(
                        label: 'Unavailable (day off)',
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TilawaChip(
                        label: 'Custom hours',
                        onTap: () {},
                      ),
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
      'TilawaMetadataChip',
      fileName: 'molecules/tilawa_metadata_chip',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: [
          GoldenTestScenario(
            name: 'Default icon + label',
            child: const TilawaPreviewWrapper(
              child: TilawaMetadataChip(
                label: '604 pages',
                icon: Icons.menu_book_rounded,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Label only',
            child: const TilawaPreviewWrapper(
              child: TilawaMetadataChip(label: '604 pages'),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark',
            child: const TilawaPreviewWrapper(
              isDark: true,
              child: TilawaMetadataChip(
                label: '604 pages',
                icon: Icons.menu_book_rounded,
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSelectionPill',
      fileName: 'molecules/tilawa_selection_pill',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: [
          GoldenTestScenario(
            name: 'Selected',
            child: TilawaPreviewWrapper(
              child: TilawaSelectionPill(
                label: 'All',
                selected: true,
                onTap: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Unselected with icon',
            child: TilawaPreviewWrapper(
              child: TilawaSelectionPill(
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
              child: TilawaSelectionPill(
                label: 'All',
                selected: true,
                onTap: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Catalog selected',
            child: TilawaPreviewWrapper(
              child: TilawaSelectionPill(
                label: 'Favorites',
                selected: true,
                style: TilawaSelectionPillStyle.catalog,
                onTap: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Catalog unselected',
            child: TilawaPreviewWrapper(
              child: TilawaSelectionPill(
                label: 'All',
                selected: false,
                style: TilawaSelectionPillStyle.catalog,
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaCountProgressRing',
      fileName: 'molecules/tilawa_count_progress_ring',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: [
          GoldenTestScenario(
            name: 'Progress default',
            child: const TilawaPreviewWrapper(
              child: SizedBox(
                width: 140,
                height: 160,
                child: Center(
                  child: TilawaCountProgressRing(
                    currentCount: 4,
                    totalCount: 7,
                    isDone: false,
                    showProgressLabel: true,
                  ),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Done state',
            child: const TilawaPreviewWrapper(
              child: SizedBox(
                width: 140,
                height: 160,
                child: Center(
                  child: TilawaCountProgressRing(
                    currentCount: 7,
                    totalCount: 7,
                    isDone: true,
                  ),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Zero-total edge',
            child: const TilawaPreviewWrapper(
              child: SizedBox(
                width: 140,
                height: 160,
                child: Center(
                  child: TilawaCountProgressRing(
                    currentCount: 0,
                    totalCount: 0,
                    isDone: false,
                  ),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Label hidden',
            child: const TilawaPreviewWrapper(
              child: SizedBox(
                width: 140,
                height: 160,
                child: Center(
                  child: TilawaCountProgressRing(
                    currentCount: 3,
                    totalCount: 7,
                    isDone: false,
                    showProgressLabel: false,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaIconActionButton',
      fileName: 'molecules/tilawa_icon_action_button',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
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
      fileName: 'molecules/tilawa_search_field',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
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
          GoldenTestScenario(
            name: 'Catalog variant',
            child: TilawaPreviewWrapper(
              child: TilawaSearchField(
                hintText: 'Search reciters',
                variant: TilawaSearchFieldVariant.catalog,
                onChanged: (_) {},
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSettingsTiles',
      fileName: 'molecules/tilawa_settings_tile',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: [
          GoldenTestScenario(
            name: 'Tile with subtitle',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 340,
                child: TilawaSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
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
      fileName: 'molecules/tilawa_feedback_strip',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
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
      fileName: 'molecules/tilawa_permission_banner',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
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
      'TilawaLanguageSwitcher',
      fileName: 'molecules/tilawa_language_switcher',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: [
          GoldenTestScenario(
            name: 'English selected',
            child: TilawaPreviewWrapper(
              child: TilawaLanguageSwitcher(
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
              child: TilawaLanguageSwitcher(
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

    goldenTest(
      'TilawaSegmentedControl',
      fileName: 'molecules/tilawa_segmented_control',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: [
          GoldenTestScenario(
            name: 'First selected',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 300,
                child: TilawaSegmentedControl<String>(
                  segments: const [
                    TilawaSegment(value: 'today', label: 'Today'),
                    TilawaSegment(value: 'monthly', label: 'Monthly'),
                  ],
                  selectedValue: 'today',
                  onValueChanged: (_) {},
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Second selected',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 300,
                child: TilawaSegmentedControl<String>(
                  segments: const [
                    TilawaSegment(value: 'today', label: 'Today'),
                    TilawaSegment(value: 'monthly', label: 'Monthly'),
                  ],
                  selectedValue: 'monthly',
                  onValueChanged: (_) {},
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark',
            child: TilawaPreviewWrapper(
              isDark: true,
              child: SizedBox(
                width: 300,
                child: TilawaSegmentedControl<String>(
                  segments: const [
                    TilawaSegment(value: 'today', label: 'Today'),
                    TilawaSegment(value: 'monthly', label: 'Monthly'),
                  ],
                  selectedValue: 'today',
                  onValueChanged: (_) {},
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSelectionTile',
      fileName: 'molecules/tilawa_selection_tile',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: [
          GoldenTestScenario(
            name: 'Unselected',
            child: TilawaPreviewWrapper(
              child: TilawaSelectionTile(
                title: 'Light Theme',
                isSelected: false,
                onTap: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Selected',
            child: TilawaPreviewWrapper(
              child: TilawaSelectionTile(
                title: 'Dark Theme',
                isSelected: true,
                onTap: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'With leading',
            child: TilawaPreviewWrapper(
              child: TilawaSelectionTile(
                leading: CircleAvatar(backgroundColor: Colors.blue, radius: 12),
                title: 'Blue',
                isSelected: true,
                onTap: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark',
            child: TilawaPreviewWrapper(
              isDark: true,
              child: TilawaSelectionTile(
                title: 'System Default',
                isSelected: false,
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaProfileAvatar',
      fileName: 'molecules/tilawa_profile_avatar',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: [
          GoldenTestScenario(
            name: 'Person fallback large',
            child: const TilawaPreviewWrapper(
              child: Center(
                child: TilawaProfileAvatar(size: 72),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Initial fallback nav',
            child: const TilawaPreviewWrapper(
              child: Center(
                child: TilawaProfileAvatar(
                  size: 28,
                  displayName: 'Ahmad',
                  fallbackStyle: TilawaProfileAvatarFallbackStyle.initial,
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Empty name safe fallback',
            child: const TilawaPreviewWrapper(
              child: Center(
                child: TilawaProfileAvatar(
                  size: 28,
                  fallbackStyle: TilawaProfileAvatarFallbackStyle.initial,
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'With verified badge',
            child: TilawaPreviewWrapper(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: const [
                    TilawaProfileAvatar(
                      size: 72,
                      displayName: 'Ahmad Ali',
                      fallbackStyle: TilawaProfileAvatarFallbackStyle.initial,
                    ),
                    TilawaVerifiedTeacherBadge(label: 'Verified Teacher'),
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
