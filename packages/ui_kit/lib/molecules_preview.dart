import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'tilawa_ui_kit.dart';

PreviewThemeData moleculesPreviewTheme() {
  return PreviewThemeData(
    materialLight: AppTheme.getLightTheme(primaryColor: AppColors.primaryCyan),
    materialDark: AppTheme.getDarkTheme(primaryColor: AppColors.primaryCyan),
  );
}

@Preview(name: 'ArabicAlphabetScrollbar', group: 'Molecules', theme: moleculesPreviewTheme)
Widget previewArabicAlphabetScrollbar() {
  return Scaffold(
    body: Center(
      child: SizedBox(
        height: 480,
        child: ArabicAlphabetScrollbar(
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

@Preview(name: 'LanguageSwitcher', group: 'Molecules', theme: moleculesPreviewTheme)
Widget previewLanguageSwitcher() {
  return Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: LanguageSwitcher(
          currentLanguage: 'en',
          languages: const ['en', 'ar'],
          getLanguageName: (code) => code == 'en' ? 'English' : 'العربية',
          onLanguageChanged: (_) {},
        ),
      ),
    ),
  );
}

@Preview(name: 'MetadataChip', group: 'Molecules', theme: moleculesPreviewTheme)
Widget previewMetadataChip() {
  return const Scaffold(
    body: Center(
      child: MetadataChip(label: '604 pages', icon: Icons.menu_book_rounded),
    ),
  );
}

@Preview(name: 'SeekBar', group: 'Molecules', theme: moleculesPreviewTheme)
Widget previewSeekBar() {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: SeekBar(
          duration: const Duration(minutes: 5),
          position: const Duration(minutes: 2, seconds: 30),
          bufferedPosition: const Duration(minutes: 3),
          onChanged: (_) {},
        ),
      ),
    ),
  );
}

@Preview(name: 'SelectionPill', group: 'Molecules', theme: moleculesPreviewTheme)
Widget previewSelectionPill() {
  return Scaffold(
    body: Center(
      child: Wrap(
        spacing: 12,
        children: [
          SelectionPill(label: 'All', selected: true, onTap: () {}),
          SelectionPill(
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

@Preview(name: 'TilawaCountProgressRing', group: 'Molecules', theme: moleculesPreviewTheme)
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

@Preview(name: 'TilawaCountProgressRing (done)', group: 'Molecules', theme: moleculesPreviewTheme)
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

@Preview(name: 'TilawaFeedbackStrip', group: 'Molecules', theme: moleculesPreviewTheme)
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

@Preview(name: 'TilawaGlassPanel', group: 'Molecules', theme: moleculesPreviewTheme)
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

@Preview(name: 'TilawaIconActionButton', group: 'Molecules', theme: moleculesPreviewTheme)
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

@Preview(name: 'TilawaSearchField', group: 'Molecules', theme: moleculesPreviewTheme)
Widget previewTilawaSearchField() {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: TilawaSearchField(
        hintText: 'Search surahs',
        onChanged: (_) {},
      ),
    ),
  );
}

@Preview(name: 'TilawaSettingsTile', group: 'Molecules', theme: moleculesPreviewTheme)
Widget previewTilawaSettingsTile() {
  return Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TilawaSettingsTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Daily prayer alerts',
          onTap: () {},
        ),
      ),
    ),
  );
}

@Preview(name: 'TilawaSettingsSwitchTile', group: 'Molecules', theme: moleculesPreviewTheme)
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

@Preview(name: 'TilawaStatusChip', group: 'Molecules', theme: moleculesPreviewTheme)
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
