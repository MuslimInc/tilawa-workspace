import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'demo_helpers.dart';

/// Molecule-layer component demos.
abstract final class MoleculesDemos {
  static Widget alphabetScrollbar(BuildContext context) {
    return GalleryDemoFrame(
      child: SizedBox(
        height: 420,
        child: ArabicAlphabetScrollbar(
          letters: const ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د'],
          selectedLetter: 'ت',
          onLetterSelected: (_) {},
          onPanUpdate: (_) {},
          onPanStart: (_) {},
          onPanEnd: (_) {},
        ),
      ),
    );
  }

  static Widget chip(BuildContext context) {
    return GalleryDemoFrame(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          TilawaChip(
            label: 'Bookmarked',
            icon: Icons.bookmark_rounded,
            onTap: () {},
          ),
          const TilawaChip(label: 'Favorite'),
        ],
      ),
    );
  }

  static Widget countProgressRing(BuildContext context) {
    return const GalleryDemoFrame(
      child: Wrap(
        spacing: 24,
        children: [
          TilawaCountProgressRing(
            currentCount: 4,
            totalCount: 7,
            isDone: false,
          ),
          TilawaCountProgressRing(
            currentCount: 7,
            totalCount: 7,
            isDone: true,
          ),
        ],
      ),
    );
  }

  static Widget feedbackStrip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GalleryDemoFrame(
      child: Column(
        children: [
          TilawaFeedbackStrip(
            icon: Icons.check_circle_rounded,
            message: 'Saved successfully',
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
          ),
          const SizedBox(height: 12),
          TilawaFeedbackStrip(
            icon: Icons.warning_amber_rounded,
            message: 'Check your settings',
            variant: TilawaFeedbackVariant.warning,
            backgroundColor: scheme.errorContainer,
            foregroundColor: scheme.onErrorContainer,
          ),
        ],
      ),
    );
  }

  static Widget glassPanel(BuildContext context) {
    return GalleryDemoFrame(
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: TilawaGlassPanel(
        enableBackdropBlur: true,
        padding: const EdgeInsets.all(20),
        child: Text(
          'Frosted glass panel',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
    );
  }

  static Widget iconActionButton(BuildContext context) {
    return GalleryDemoFrame(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TilawaIconActionButton(
            icon: Icons.favorite_border,
            onTap: () {},
          ),
          const SizedBox(width: 16),
          TilawaIconActionButton(
            icon: Icons.favorite,
            onTap: () {},
            isActive: true,
          ),
        ],
      ),
    );
  }

  static Widget languageSwitcher(BuildContext context) {
    return GalleryDemoFrame(
      child: _LanguageSwitcherDemo(),
    );
  }

  static Widget metadataChip(BuildContext context) {
    return const GalleryDemoFrame(
      child: TilawaMetadataChip(
        label: '604 pages',
        icon: Icons.menu_book_rounded,
      ),
    );
  }

  static Widget permissionBanner(BuildContext context) {
    return GalleryDemoFrame(
      child: TilawaPermissionBanner(
        message: 'Enable notifications to receive prayer alerts',
        actionLabel: 'Enable',
        onAction: () {},
      ),
    );
  }

  static Widget searchField(BuildContext context) {
    return GalleryDemoFrame(
      child: _SearchFieldDemo(),
    );
  }

  static Widget sectionHeader(BuildContext context) {
    return GalleryDemoFrame(
      alignment: Alignment.centerLeft,
      child: TilawaSectionHeader.settings(context, title: 'Preferences'),
    );
  }

  static Widget seekBar(BuildContext context) {
    return GalleryDemoFrame(
      child: SeekBar(
        duration: const Duration(minutes: 5),
        position: const Duration(minutes: 2, seconds: 30),
        bufferedPosition: const Duration(minutes: 3),
        onChanged: (_) {},
      ),
    );
  }

  static Widget segmentedControl(BuildContext context) {
    return GalleryDemoFrame(
      child: _SegmentedControlDemo(),
    );
  }

  static Widget selectionPill(BuildContext context) {
    return GalleryDemoFrame(
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
    );
  }

  static Widget selectionTile(BuildContext context) {
    return GalleryDemoFrame(
      child: Column(
        children: [
          TilawaSelectionTile(
            title: 'Light theme',
            isSelected: true,
            onTap: () {},
          ),
          TilawaSelectionTile(
            title: 'Dark theme',
            isSelected: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  static Widget settingsTile(BuildContext context) {
    return GalleryDemoFrame(
      child: Column(
        children: [
          TilawaSettingsTile(
            icon: Icons.language,
            title: 'Language',
            onTap: () {},
          ),
          _SettingsSwitchDemo(),
        ],
      ),
    );
  }

  static Widget statusChip(BuildContext context) {
    return const GalleryDemoFrame(
      child: TilawaStatusChip(
        label: 'Live',
        icon: Icons.wifi_tethering_rounded,
      ),
    );
  }
}

class _LanguageSwitcherDemo extends StatefulWidget {
  @override
  State<_LanguageSwitcherDemo> createState() => _LanguageSwitcherDemoState();
}

class _LanguageSwitcherDemoState extends State<_LanguageSwitcherDemo> {
  String _language = 'en';

  @override
  Widget build(BuildContext context) {
    return TilawaLanguageSwitcher(
      currentLanguage: _language,
      languages: const ['en', 'ar'],
      getLanguageName: (code) => code == 'en' ? 'English' : 'العربية',
      onLanguageChanged: (code) => setState(() => _language = code),
    );
  }
}

class _SearchFieldDemo extends StatefulWidget {
  @override
  State<_SearchFieldDemo> createState() => _SearchFieldDemoState();
}

class _SearchFieldDemoState extends State<_SearchFieldDemo> {
  final _controller = TextEditingController(text: 'Al-Baqarah');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TilawaSearchField(
      hintText: 'Search surahs',
      controller: _controller,
      onChanged: (_) => setState(() {}),
      onClear: () => setState(_controller.clear),
    );
  }
}

class _SegmentedControlDemo extends StatefulWidget {
  @override
  State<_SegmentedControlDemo> createState() => _SegmentedControlDemoState();
}

class _SegmentedControlDemoState extends State<_SegmentedControlDemo> {
  String _value = 'today';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: TilawaSegmentedControl<String>(
        segments: const [
          TilawaSegment(value: 'today', label: 'Today'),
          TilawaSegment(value: 'monthly', label: 'Monthly'),
        ],
        selectedValue: _value,
        onValueChanged: (v) => setState(() => _value = v),
      ),
    );
  }
}

class _SettingsSwitchDemo extends StatefulWidget {
  @override
  State<_SettingsSwitchDemo> createState() => _SettingsSwitchDemoState();
}

class _SettingsSwitchDemoState extends State<_SettingsSwitchDemo> {
  bool _darkMode = true;

  @override
  Widget build(BuildContext context) {
    return TilawaSettingsSwitchTile(
      icon: Icons.dark_mode_outlined,
      title: 'Dark mode',
      value: _darkMode,
      onChanged: (v) => setState(() => _darkMode = v),
      showDivider: false,
    );
  }
}
