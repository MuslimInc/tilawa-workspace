import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit_v2/tilawa_ui_kit_v2.dart';

void main() => runApp(const _GalleryApp());

class _GalleryApp extends StatelessWidget {
  const _GalleryApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tilawa UI Kit v2 Gallery',
      debugShowCheckedModeBanner: false,
      theme: buildTilawaMaterialTheme(),
      home: TilawaTheme.light(child: const _GalleryShell()),
    );
  }
}

class _GalleryShell extends StatefulWidget {
  const _GalleryShell();

  @override
  State<_GalleryShell> createState() => _GalleryShellState();
}

class _GalleryShellState extends State<_GalleryShell> {
  int _tab = 0;
  bool _dark = false;
  bool _playing = true;

  @override
  Widget build(BuildContext context) {
    final c = TilawaTheme.of(context).tokens.colors;

    final pages = <Widget>[
      _HomePage(playing: _playing, onTogglePlay: _togglePlay),
      const _PlayerPage(),
      const _QiblaPage(),
      const _RecitersPage(),
      _ProfilePage(dark: _dark, onToggleDark: (v) => setState(() => _dark = v)),
    ];

    return Scaffold(
      backgroundColor: c.bgPage,
      body: Stack(
        children: [
          Positioned.fill(child: pages[_tab]),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TilawaBottomTabBar(
              items: const [
                TilawaTabItem(label: 'Home', icon: Icons.home_filled),
                TilawaTabItem(label: 'Player', icon: Icons.play_circle_fill),
                TilawaTabItem(label: 'Qibla', icon: Icons.explore),
                TilawaTabItem(label: 'Reciters', icon: Icons.mic_none),
                TilawaTabItem(label: 'Profile', icon: Icons.person_outline),
              ],
              currentIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
        ],
      ),
    );
  }

  void _togglePlay() => setState(() => _playing = !_playing);
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.playing, required this.onTogglePlay});

  final bool playing;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 200),
            children: [
              TilawaAppHeader(
                greeting: 'Assalamu alaikum',
                name: 'Muhammad',
                subtitle:
                    'May your day be filled with peace and tranquility.',
                profileInitials: 'M',
                onProfilePressed: () {},
                search: const TilawaSearchField(
                  placeholder: 'Search surahs, reciters…',
                ),
              ),
              const SizedBox(height: 8),
              const TilawaLastReadHero(
                eyebrow: 'Continue reading',
                title: 'Al-Baqarah',
                arabicTitle: 'البقرة',
                subtitle: 'Verse 142 · 49% complete',
                progress: 0.49,
                percentLabel: '49%',
                onResume: _noop,
              ),
              const TilawaSectionHeader(
                title: 'Continue listening',
                actionLabel: 'See all',
              ),
              TilawaSurahRow(
                number: 36,
                name: 'Ya-Sin',
                arabicName: 'يس',
                meta: 'Mishary Alafasy · 83 verses',
                onTap: () {},
              ),
              const TilawaDivider(inset: TilawaDividerInset.trailingFromIcon),
              TilawaSurahRow(
                number: 67,
                name: 'Al-Mulk',
                arabicName: 'الملك',
                meta: 'Mishary Alafasy · 30 verses',
                onTap: () {},
              ),
              const TilawaDivider(inset: TilawaDividerInset.trailingFromIcon),
              TilawaSurahRow(
                number: 18,
                name: 'Al-Kahf',
                arabicName: 'الكهف',
                meta: 'Mishary Alafasy · 110 verses',
                onTap: () {},
              ),
              const TilawaSectionHeader(title: 'For you'),
              TilawaStatGroup(
                items: const [
                  TilawaStatCard(value: '14', label: 'Surahs'),
                  TilawaStatCard(value: '7', unit: 'd', label: 'Streak'),
                  TilawaStatCard(value: '3.2', unit: 'h', label: 'Listened'),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 86,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TilawaNowPlayingDock(
                title: 'Surah Al-Fatiha',
                subtitle: 'Mishary Alafasy',
                progress: 0.34,
                isPlaying: playing,
                onPlayPause: onTogglePlay,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerPage extends StatelessWidget {
  const _PlayerPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TilawaPlayerHeader(
          eyebrow: 'Now Reciting',
          title: 'Surah Al-Fatiha · Mishary Alafasy',
          onBack: () {},
          onMore: () {},
        ),
        const Expanded(
          child: TilawaVerseView(
            verseArabic:
                'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
            translation:
                'All praise is for Allah—Lord of all worlds.',
            counterLabel: 'Ayah 2 of 7',
          ),
        ),
        TilawaPlayerTransport(
          progress: 0.34,
          elapsed: '0:34',
          remaining: '-1:12',
          isPlaying: true,
          onPlayPause: () {},
          onPrevious: () {},
          onNext: () {},
          onRepeat: () {},
          onShuffle: () {},
        ),
      ],
    );
  }
}

class _QiblaPage extends StatelessWidget {
  const _QiblaPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 110),
      child: Column(
        children: [
          const TilawaEyebrow('Qibla'),
          const SizedBox(height: 8),
          Text(
            'Facing Makkah',
            style: TilawaTheme.of(context).typography.h3Mobile.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '112° NE · Adjust your bearing until the needle aligns with the marker.',
            textAlign: TextAlign.center,
            style: TilawaTheme.of(context).typography.captionMobile,
          ),
          const SizedBox(height: 24),
          const TilawaCompassRose(headingDegrees: 112),
        ],
      ),
    );
  }
}

class _RecitersPage extends StatelessWidget {
  const _RecitersPage();

  final _reciters = const [
    ('Mishary Alafasy', 'Hafs · Arabic', true),
    ('Abdul Basit', 'Hafs · Arabic', false),
    ('Maher Al Muaiqly', 'Hafs · Arabic', false),
    ('Saud Al-Shuraim', 'Hafs · Arabic', false),
    ('Sa\'ad Al-Ghamdi', 'Hafs · Arabic', false),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 200),
      children: [
        const TilawaSectionHeader(title: 'Reciters'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: TilawaSearchField(placeholder: 'Search reciters'),
        ),
        const SizedBox(height: 8),
        for (final r in _reciters) ...[
          TilawaReciterRow(
            name: r.$1,
            meta: r.$2,
            isSelected: r.$3,
            onTap: () {},
          ),
          const TilawaDivider(inset: TilawaDividerInset.trailingFromIcon),
        ],
      ],
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({required this.dark, required this.onToggleDark});

  final bool dark;
  final ValueChanged<bool> onToggleDark;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 200),
      children: [
        const TilawaProfileHero(
          initials: 'M',
          name: 'Muhammad Kamel',
          email: 'muhammad@example.com',
        ),
        const SizedBox(height: 16),
        TilawaStatGroup(
          items: const [
            TilawaStatCard(value: '37', label: 'Surahs'),
            TilawaStatCard(value: '14', unit: 'd', label: 'Streak'),
            TilawaStatCard(value: '24', unit: 'h', label: 'Listened'),
          ],
        ),
        const TilawaSectionHeader(title: 'Library', quiet: true),
        TilawaListGroup(
          children: [
            TilawaListItem(
              icon: Icons.bookmark_border,
              label: 'Bookmarks',
              showChevron: true,
              onTap: () {},
            ),
            TilawaListItem(
              icon: Icons.download_outlined,
              label: 'Downloads',
              showChevron: true,
              onTap: () {},
            ),
            TilawaListItem(
              icon: Icons.history,
              label: 'History',
              showChevron: true,
              onTap: () {},
            ),
          ],
        ),
        const TilawaSectionHeader(title: 'Preferences', quiet: true),
        TilawaListGroup(
          children: [
            TilawaListItem(
              icon: Icons.dark_mode_outlined,
              label: 'Dark mode',
              trailing: TilawaToggle(value: dark, onChanged: onToggleDark),
            ),
            TilawaListItem(
              icon: Icons.speed,
              label: 'Playback speed',
              trailing: const Text('1.0×'),
              onTap: () {},
            ),
          ],
        ),
        const TilawaSectionHeader(title: 'Account', quiet: true),
        TilawaListGroup(
          children: [
            TilawaListItem(
              icon: Icons.logout,
              label: 'Sign out',
              tone: TilawaListItemTone.danger,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

void _noop() {}
