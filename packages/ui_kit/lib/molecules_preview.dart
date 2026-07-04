import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'tilawa_ui_kit.dart';

PreviewThemeData moleculesPreviewTheme() {
  return PreviewThemeData(
    materialLight: AppTheme.getLightTheme(primaryColor: AppColors.primaryCyan),
    materialDark: AppTheme.getDarkTheme(
      primaryColor: AppColors.primaryCyan,
      isDefaultPreset: true,
    ),
  );
}

@Preview(
  name: 'TilawaAlphabetScrollbar',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaAlphabetScrollbar() {
  return Scaffold(
    body: Center(
      child: SizedBox(
        height: 480,
        child: TilawaAlphabetScrollbar(
          letters: const ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د'],
          selectedLetter: 'ت',
          onLetterSelected: (_) {},
          onPanUpdate: (_) {},
          onPanStart: (_) {},
          onPanEnd: (_) {},
        ),
      ),
    ),
  );
}

@Preview(
  name: 'TilawaLanguageSwitcher',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaLanguageSwitcher() {
  return Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: TilawaLanguageSwitcher(
          currentLanguage: 'en',
          languages: const ['en', 'ar'],
          getLanguageName: (code) => code == 'en' ? 'English' : 'العربية',
          onLanguageChanged: (_) {},
        ),
      ),
    ),
  );
}

@Preview(
  name: 'TilawaLanguageSwitcher (Arabic selected)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaLanguageSwitcherArabicSelected() {
  return Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: TilawaLanguageSwitcher(
          currentLanguage: 'ar',
          languages: const ['en', 'ar'],
          getLanguageName: (code) => code == 'en' ? 'English' : 'العربية',
          onLanguageChanged: (_) {},
        ),
      ),
    ),
  );
}

@Preview(
  name: 'TilawaMetadataChip',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaMetadataChip() {
  return const Scaffold(
    body: Center(
      child: TilawaMetadataChip(
        label: '604 pages',
        icon: Icons.menu_book_rounded,
      ),
    ),
  );
}

@Preview(
  name: 'TilawaMetadataChip (dark)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaMetadataChipDark() {
  return const Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: TilawaMetadataChip(
        label: '604 pages',
        icon: Icons.menu_book_rounded,
      ),
    ),
  );
}

@Preview(
  name: 'TilawaSeekBar',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaSeekBar() {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: TilawaSeekBar(
          duration: const Duration(minutes: 5),
          position: const Duration(minutes: 2, seconds: 30),
          bufferedPosition: const Duration(minutes: 3),
          onChanged: (_) {},
        ),
      ),
    ),
  );
}

@Preview(
  name: 'TilawaSelectionPill',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaSelectionPill() {
  return Scaffold(
    body: Center(
      child: Wrap(
        spacing: 12,
        children: [
          TilawaSelectionPill(label: 'All', selected: true, onTap: () {}),
          TilawaSelectionPill(
            label: 'Recent',
            selected: false,
            icon: Icons.history,
            onTap: () {},
          ),
        ],
      ),
    ),
  );
}

@Preview(
  name: 'TilawaSelectionPill (dark)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaSelectionPillDark() {
  return Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: TilawaSelectionPill(label: 'All', selected: true, onTap: () {}),
    ),
  );
}

@Preview(name: 'TilawaChip', group: 'Molecules', theme: moleculesPreviewTheme)
Widget previewTilawaChip() {
  return Scaffold(
    body: Center(
      child: TilawaChip(
        label: 'Bookmarked',
        icon: Icons.bookmark_rounded,
        onTap: () {},
      ),
    ),
  );
}

@Preview(
  name: 'TilawaChip (label only)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaChipLabelOnly() {
  return const Scaffold(
    body: Center(child: TilawaChip(label: 'Favorite')),
  );
}

@Preview(
  name: 'TilawaChip (RTL)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaChipRtl() {
  return const Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: Center(
        child: TilawaChip(label: 'محفوظ', icon: Icons.bookmark_rounded),
      ),
    ),
  );
}

@Preview(
  name: 'TilawaCountProgressRing',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaCountProgressRing() {
  return const Scaffold(
    body: Center(
      child: TilawaCountProgressRing(
        currentCount: 4,
        totalCount: 7,
        isDone: false,
      ),
    ),
  );
}

@Preview(
  name: 'TilawaCountProgressRing (done)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaCountProgressRingDone() {
  return const Scaffold(
    body: Center(
      child: TilawaCountProgressRing(
        currentCount: 7,
        totalCount: 7,
        isDone: true,
      ),
    ),
  );
}

@Preview(
  name: 'TilawaFeedbackStrip',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaFeedbackStrip() {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
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
  );
}

@Preview(
  name: 'TilawaFeedbackStrip (dark)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaFeedbackStripDark() {
  return Scaffold(
    backgroundColor: Colors.black,
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: TilawaFeedbackStrip(
          icon: Icons.check_circle_rounded,
          message: 'Saved successfully',
          backgroundColor: const Color(0xFF1B3A5C),
          foregroundColor: const Color(0xFF90CAF9),
        ),
      ),
    ),
  );
}

@Preview(
  name: 'TilawaFeedbackStrip (RTL)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaFeedbackStripRtl() {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
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
    ),
  );
}

@Preview(
  name: 'TilawaPermissionBanner',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaPermissionBanner() {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: TilawaPermissionBanner(
          message: 'Enable notifications to receive prayer alerts',
          actionLabel: 'Enable',
          onAction: () {},
        ),
      ),
    ),
  );
}

@Preview(
  name: 'TilawaPermissionBanner (dark)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaPermissionBannerDark() {
  return Scaffold(
    backgroundColor: Colors.black,
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: TilawaPermissionBanner(
          message: 'Enable notifications to receive prayer alerts',
          actionLabel: 'Enable',
          onAction: () {},
        ),
      ),
    ),
  );
}

@Preview(
  name: 'TilawaGlassPanel',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaGlassPanel() {
  return Scaffold(
    backgroundColor: Colors.indigo,
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: TilawaGlassPanel(
          enableBackdropBlur: true,
          padding: const EdgeInsets.all(20),
          child: const Text(
            'Frosted glass panel',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    ),
  );
}

@Preview(
  name: 'TilawaIconActionButton',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaIconActionButton() {
  return Scaffold(
    body: Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TilawaIconActionButton(icon: Icons.favorite_border, onTap: () {}),
          const SizedBox(width: 16),
          TilawaIconActionButton(
            icon: Icons.favorite,
            onTap: () {},
            isActive: true,
          ),
        ],
      ),
    ),
  );
}

@Preview(
  name: 'TilawaIconActionButton (dark)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaIconActionButtonDark() {
  return Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: TilawaIconActionButton(icon: Icons.favorite_border, onTap: () {}),
    ),
  );
}

@Preview(
  name: 'TilawaSearchField',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaSearchField() {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: TilawaSearchField(hintText: 'Search surahs', onChanged: (_) {}),
    ),
  );
}

@Preview(
  name: 'TilawaSearchField (with text)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaSearchFieldWithText() {
  final controller = TextEditingController(text: 'Al-Baqarah');
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: TilawaSearchField(
        hintText: 'Search surahs',
        controller: controller,
        onChanged: (_) {},
        onClear: controller.clear,
      ),
    ),
  );
}

@Preview(
  name: 'TilawaSearchField (RTL)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaSearchFieldRtl() {
  return const Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: _SearchFieldRtlPreviewBody(),
      ),
    ),
  );
}

class _SearchFieldRtlPreviewBody extends StatelessWidget {
  const _SearchFieldRtlPreviewBody();

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: 'الفاتحة');
    return TilawaSearchField(
      hintText: 'ابحث في السور',
      controller: controller,
      onChanged: (_) {},
      onClear: controller.clear,
    );
  }
}

@Preview(
  name: 'TilawaSearchField (dark)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaSearchFieldDark() {
  return Scaffold(
    backgroundColor: Colors.black,
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: TilawaSearchField(hintText: 'Search surahs', onChanged: (_) {}),
    ),
  );
}

@Preview(
  name: 'TilawaSettingsTile',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaSettingsTile() {
  return Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TilawaSettingsTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          onTap: () {},
        ),
      ),
    ),
  );
}

@Preview(
  name: 'TilawaSettingsTile (no subtitle)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaSettingsTileNoSubtitle() {
  return Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TilawaSettingsTile(
          icon: Icons.language,
          title: 'Language',
          onTap: () {},
          showDivider: false,
        ),
      ),
    ),
  );
}

@Preview(
  name: 'TilawaSettingsTile (RTL)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaSettingsTileRtl() {
  return const Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: TilawaSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'الإشعارات',
            onTap: _noop,
          ),
        ),
      ),
    ),
  );
}

@Preview(
  name: 'TilawaSettingsSwitchTile',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaSettingsSwitchTile() {
  return Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TilawaSettingsSwitchTile(
          icon: Icons.dark_mode_outlined,
          title: 'Dark mode',
          value: true,
          onChanged: (_) {},
        ),
      ),
    ),
  );
}

@Preview(
  name: 'TilawaSettingsSwitchTile (off)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaSettingsSwitchTileOff() {
  return Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TilawaSettingsSwitchTile(
          icon: Icons.dark_mode_outlined,
          title: 'Dark mode',
          value: false,
          onChanged: (_) {},
          showDivider: false,
        ),
      ),
    ),
  );
}

@Preview(
  name: 'TilawaSettingsSwitchTile (RTL)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaSettingsSwitchTileRtl() {
  return const Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: TilawaSettingsSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'إشعارات الصلاة',
            value: true,
            onChanged: _noopBool,
            showDivider: false,
          ),
        ),
      ),
    ),
  );
}

@Preview(
  name: 'TilawaStatusChip',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaStatusChip() {
  return const Scaffold(
    body: Center(
      child: TilawaStatusChip(
        label: 'Live',
        icon: Icons.wifi_tethering_rounded,
      ),
    ),
  );
}

@Preview(
  name: 'TilawaStatusChip (dark)',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaStatusChipDark() {
  return const Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: TilawaStatusChip(
        label: 'Live',
        icon: Icons.wifi_tethering_rounded,
      ),
    ),
  );
}

@Preview(
  name: 'TilawaMetricTile',
  group: 'Molecules',
  theme: moleculesPreviewTheme,
)
Widget previewTilawaMetricTile() {
  return Scaffold(
    body: Center(
      child: SizedBox(
        width: 360,
        child: TilawaMetricTileStrip(
          metrics: [
            TilawaMetricData(
              value: '2',
              label: 'Pending',
              icon: Icons.inbox_outlined,
              tint: TilawaSemanticTint.ink,
            ),
            TilawaMetricData(
              value: '5',
              label: 'Upcoming',
              icon: Icons.event_outlined,
              tint: TilawaSemanticTint.scholar,
            ),
            TilawaMetricData(
              value: '48',
              label: 'Bookable slots',
              icon: Icons.schedule_outlined,
              tint: TilawaSemanticTint.neutral,
            ),
          ],
        ),
      ),
    ),
  );
}

void _noop() {}
void _noopBool(bool _) {}
