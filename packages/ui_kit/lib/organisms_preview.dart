import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'tilawa_ui_kit.dart';

PreviewThemeData organismsPreviewTheme() {
  return PreviewThemeData(
    materialLight: AppTheme.getLightTheme(primaryColor: AppColors.primaryCyan),
    materialDark: AppTheme.getDarkTheme(primaryColor: AppColors.primaryCyan),
  );
}

@Preview(name: 'TilawaMediaPlayerBar', group: 'Organisms', theme: organismsPreviewTheme)
Widget previewTilawaMediaPlayerBar() {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: TilawaMediaPlayerBar(
          title: 'Surah Al-Fatiha',
          subtitle: 'Abdul Basit',
          progress: 0.5,
          isPlaying: true,
          canGoPrevious: true,
          canGoNext: true,
          onPlayPause: () {},
          onPrevious: () {},
          onNext: () {},
          onTap: () {},
        ),
      ),
    ),
  );
}

@Preview(name: 'ImmersiveComposerScaffold', group: 'Organisms', theme: organismsPreviewTheme)
Widget previewImmersiveComposerScaffold() {
  return ImmersiveComposerScaffold(
    title: 'Compose',
    subtitle: 'Draft a new ayah image',
    preview: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo, Colors.purple],
        ),
      ),
      child: const Center(
        child: Text(
          'Preview canvas',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    ),
    bottomPanel: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.text_fields)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.color_lens)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
        ],
      ),
    ),
    onClose: () {},
  );
}

@Preview(name: 'TilawaAdaptiveShell', group: 'Organisms', theme: organismsPreviewTheme)
Widget previewTilawaAdaptiveShell() {
  return TilawaAdaptiveShell(
    selectedIndex: 0,
    onDestinationSelected: (_) {},
    destinations: const [
      TilawaNavDestination(label: 'Home', icon: Icons.home_outlined),
      TilawaNavDestination(label: 'Quran', icon: Icons.menu_book_outlined),
      TilawaNavDestination(label: 'Library', icon: Icons.bookmark_outline),
      TilawaNavDestination(label: 'Settings', icon: Icons.settings_outlined),
    ],
    bottomPlayer: const SizedBox.shrink(),
    child: const Center(child: Text('Selected screen')),
  );
}

@Preview(name: 'TilawaBackdropImageLayer', group: 'Organisms', theme: organismsPreviewTheme)
Widget previewTilawaBackdropImageLayer() {
  return const Scaffold(
    body: TilawaBackdropImageLayer(
      image: NetworkImage('https://picsum.photos/800/1200'),
      blurAmount: 12,
      overlayOpacity: 0.4,
    ),
  );
}

@Preview(name: 'TilawaSettingsGroup', group: 'Organisms', theme: organismsPreviewTheme)
Widget previewTilawaSettingsGroup() {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
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
  );
}
