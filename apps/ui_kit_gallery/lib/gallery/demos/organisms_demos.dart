import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'demo_helpers.dart';

/// Organism-layer component demos.
abstract final class OrganismsDemos {
  static Widget adaptiveShell(BuildContext context) {
    return _AdaptiveShellDemo();
  }

  static Widget backdropImageLayer(BuildContext context) {
    return const GalleryDemoFrame(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 320,
        width: double.infinity,
        child: TilawaBackdropImageLayer(
          image: NetworkImage('https://picsum.photos/800/1200'),
          blurAmount: 12,
          overlayOpacity: 0.4,
        ),
      ),
    );
  }

  static Widget bottomSheetScaffold(BuildContext context) {
    return GalleryDemoFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TilawaButton(
            text: 'Open modal sheet',
            onPressed: () => _openSheet(context),
          ),
          const SizedBox(height: 24),
          const Text(
            'Inline preview',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const TilawaBottomSheetScaffold(
              topBar: Text('Sheet title'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sheet body content'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget immersiveComposer(BuildContext context) {
    return SizedBox(
      height: 520,
      child: ImmersiveComposerScaffold(
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
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.text_fields),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.color_lens),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
            ],
          ),
        ),
        onClose: () {},
      ),
    );
  }

  static Widget mediaPlayerBar(BuildContext context) {
    return GalleryDemoFrame(
      child: Column(
        children: [
          TilawaMediaPlayerBar(
            layoutWidth: 420,
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
          const SizedBox(height: 16),
          TilawaMediaPlayerBar(
            layoutWidth: 360,
            title: 'Surah Al-Fatiha',
            subtitle: 'Abdul Basit',
            progress: 0.35,
            isPlaying: true,
            canGoPrevious: true,
            canGoNext: true,
            isSleepTimerEnabled: true,
            onPlayPause: () {},
            onNext: () {},
            onTap: () {},
          ),
        ],
      ),
    );
  }

  static Widget settingsGroup(BuildContext context) {
    return GalleryDemoFrame(
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
    );
  }

  static Widget shareFooterBar(BuildContext context) {
    return GalleryDemoFrame(
      child: SizedBox(
        width: 360,
        child: TilawaShareFooterBar(
          primaryLabel: 'Surah Al-Fatiha',
          secondaryLabel: 'Ayah 1',
        ),
      ),
    );
  }

  static Future<void> _openSheet(BuildContext context) {
    return showTilawaModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: TilawaBottomSheetScaffold.modalShape(context),
      builder: (sheetContext) {
        return TilawaBottomSheetScaffold(
          topBar: Text(
            'Modal sheet',
            style: Theme.of(sheetContext).textTheme.titleMedium,
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('Drag the handle down to dismiss.'),
            ),
          ],
        );
      },
    );
  }
}

class _AdaptiveShellDemo extends StatefulWidget {
  @override
  State<_AdaptiveShellDemo> createState() => _AdaptiveShellDemoState();
}

class _AdaptiveShellDemoState extends State<_AdaptiveShellDemo> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 520,
      child: TilawaAdaptiveShell(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          TilawaNavDestination(label: 'Home', icon: Icons.home_outlined),
          TilawaNavDestination(label: 'Quran', icon: Icons.menu_book_outlined),
          TilawaNavDestination(label: 'Library', icon: Icons.bookmark_outline),
          TilawaNavDestination(
            label: 'Settings',
            icon: Icons.settings_outlined,
          ),
        ],
        bottomPlayer: const SizedBox.shrink(),
        child: Center(
          child: Text('Tab ${_index + 1}'),
        ),
      ),
    );
  }
}
