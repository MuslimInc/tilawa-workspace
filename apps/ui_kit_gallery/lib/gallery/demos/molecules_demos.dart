import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'demo_helpers.dart';

/// Molecule-layer component demos.
abstract final class MoleculesDemos {
  static Widget appBar(BuildContext context) {
    return Scaffold(
      appBar: TilawaAppBar(
        title: 'Feature screen',
        actions: [
          TilawaIconActionButton(
            icon: Icons.search,
            onTap: () {},
          ),
        ],
      ),
      body: const GalleryDemoFrame(
        child: Text('Standard TilawaAppBar with framed toolbar actions.'),
      ),
    );
  }

  static Widget alphabetScrollbar(BuildContext context) {
    return GalleryDemoFrame(
      child: SizedBox(
        height: 420,
        child: TilawaAlphabetScrollbar(
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

  static Widget catalogAppBar(BuildContext context) {
    return Scaffold(
      appBar: TilawaCatalogAppBar(
        preferredHeight: TilawaAppBarConfig.catalogTitleAndSearchHeight(
          context,
        ),
        title: 'Reciters',
        automaticallyImplyLeading: true,
        bottomContent: TilawaSearchField(
          hintText: 'Search reciters',
          variant: TilawaSearchFieldVariant.catalog,
          onChanged: (_) {},
        ),
      ),
      body: const GalleryDemoFrame(
        child: Text('Catalog chrome with parchment surface and search row.'),
      ),
    );
  }

  static Widget catalogSettings(BuildContext context) {
    return GalleryDemoFrame(
      padding: EdgeInsets.zero,
      child: _CatalogSettingsDemo(),
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
            backgroundColor: scheme.tertiaryContainer,
            foregroundColor: scheme.onTertiaryContainer,
          ),
          const SizedBox(height: 12),
          TilawaFeedbackStrip(
            icon: Icons.error_outline_rounded,
            message: 'Something went wrong',
            variant: TilawaFeedbackVariant.error,
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

  static Widget navigationRow(BuildContext context) {
    return GalleryDemoFrame(
      child: TilawaHubNavigationGroup(
        children: [
          TilawaNavigationRow(
            icon: Icons.menu_book_outlined,
            title: 'Quran',
            subtitle: 'Resume reading or browse surahs',
            onTap: () {},
          ),
          TilawaNavigationRow(
            icon: Icons.bookmark_outline,
            title: 'Library',
            subtitle: 'Bookmarks, playlists, and history',
            onTap: () {},
            showDivider: false,
          ),
        ],
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

  static Widget primaryFab(BuildContext context) {
    return Scaffold(
      floatingActionButton: TilawaPrimaryFab(
        icon: Icons.add,
        heroTag: 'gallery_primary_fab',
        label: 'Create',
        onPressed: () {},
      ),
      floatingActionButtonLocation: TilawaFabLocation.placement(
        TilawaFabPlacement.end,
      ),
      body: const GalleryDemoFrame(
        child: Text('Primary FAB with token-backed placement helper.'),
      ),
    );
  }

  static Widget quickFilterBar(BuildContext context) {
    return GalleryDemoFrame(
      child: _QuickFilterBarDemo(),
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
      child: TilawaSeekBar(
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

  static Widget settingsSwitchTile(BuildContext context) {
    return GalleryDemoFrame(
      child: _SettingsSwitchDemo(showDivider: false),
    );
  }

  static Widget settingsTile(BuildContext context) {
    return GalleryDemoFrame(
      child: TilawaSettingsTile(
        icon: Icons.language,
        title: 'Language',
        onTap: () {},
        showDivider: false,
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

  static Widget metricTile(BuildContext context) {
    return const GalleryDemoFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          SizedBox(
            width: 220,
            child: TilawaMetricTile(
              data: TilawaMetricData(
                value: '12',
                label: 'Pending requests',
                icon: Icons.inbox_outlined,
                tint: TilawaSemanticTint.ink,
                helperText: '+3 this week',
              ),
            ),
          ),
          TilawaMetricTileStrip(
            metrics: [
              TilawaMetricData(
                value: '2',
                label: 'Pending requests',
                icon: Icons.inbox_outlined,
                tint: TilawaSemanticTint.ink,
              ),
              TilawaMetricData(
                value: '5',
                label: 'Upcoming sessions',
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
        ],
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
  const _SettingsSwitchDemo({this.showDivider = true});

  final bool showDivider;

  @override
  State<_SettingsSwitchDemo> createState() => _SettingsSwitchDemoState();
}

class _CatalogSettingsDemo extends StatefulWidget {
  @override
  State<_CatalogSettingsDemo> createState() => _CatalogSettingsDemoState();
}

class _CatalogSettingsDemoState extends State<_CatalogSettingsDemo> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return TilawaCatalogSettingsBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TilawaCatalogSettingsSection(
            title: 'Account',
            topSpacing: 0,
            children: [
              TilawaCatalogSettingsProfileRow(
                avatar: CircleAvatar(
                  radius: 28,
                  child: Icon(Icons.person_outline),
                ),
                title: 'Guest profile',
                onTap: () {},
              ),
              TilawaCatalogSettingsLinkRow(
                title: 'Sign in',
                onTap: () {},
              ),
            ],
          ),
          TilawaCatalogSettingsSection(
            title: 'Preferences',
            children: [
              TilawaCatalogSettingsSwitchRow(
                title: 'Prayer reminders',
                value: _notifications,
                onChanged: (value) => setState(() => _notifications = value),
              ),
              TilawaCatalogSettingsLinkRow(
                title: 'Language',
                trailing: const Text('English'),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickFilterBarDemo extends StatefulWidget {
  @override
  State<_QuickFilterBarDemo> createState() => _QuickFilterBarDemoState();
}

class _QuickFilterBarDemoState extends State<_QuickFilterBarDemo> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return TilawaQuickFilterBar(
      trailing: TextButton(onPressed: () {}, child: const Text('Clear')),
      children: [
        TilawaSelectionPill(
          label: 'All',
          selected: _filter == 'all',
          style: TilawaSelectionPillStyle.catalog,
          onTap: () => setState(() => _filter = 'all'),
        ),
        TilawaSelectionPill(
          label: 'Recent',
          selected: _filter == 'recent',
          style: TilawaSelectionPillStyle.catalog,
          onTap: () => setState(() => _filter = 'recent'),
        ),
        TilawaSelectionPill(
          label: 'Bookmarked',
          selected: _filter == 'bookmarked',
          style: TilawaSelectionPillStyle.catalog,
          onTap: () => setState(() => _filter = 'bookmarked'),
        ),
      ],
    );
  }
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
      showDivider: widget.showDivider,
    );
  }
}
