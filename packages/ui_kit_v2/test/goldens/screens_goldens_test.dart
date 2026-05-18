import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit_v2/tilawa_ui_kit_v2.dart';

import 'golden_constraints.dart';
import 'preview_wrapper.dart';

void _noop() {}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TilawaAppHeader(
            greeting: 'Assalamu alaikum',
            name: 'Muhammad',
            subtitle:
                'May your day be filled with peace and tranquility.',
            profileInitials: 'M',
            onProfilePressed: _noop,
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
            onTap: _noop,
          ),
          const TilawaDivider(inset: TilawaDividerInset.trailingFromIcon),
          TilawaSurahRow(
            number: 67,
            name: 'Al-Mulk',
            arabicName: 'الملك',
            meta: 'Mishary Alafasy · 30 verses',
            onTap: _noop,
          ),
        ],
      ),
    );
  }
}

class _PlayerScreen extends StatelessWidget {
  const _PlayerScreen();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TilawaPlayerHeader(
          eyebrow: 'Now Reciting',
          title: 'Surah Al-Fatihah · Mishary Alafasy',
          onBack: _noop,
          onMore: _noop,
        ),
        const Expanded(
          child: TilawaVerseView(
            verseArabic: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
            translation: 'All praise is for Allah—Lord of all worlds.',
            counterLabel: 'Ayah 2 of 7',
          ),
        ),
        TilawaPlayerTransport(
          progress: 0.34,
          elapsed: '0:34',
          remaining: '-1:12',
          isPlaying: true,
          onPlayPause: _noop,
          onPrevious: _noop,
          onNext: _noop,
          onRepeat: _noop,
          onShuffle: _noop,
        ),
      ],
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TilawaProfileHero(
            initials: 'M',
            name: 'Muhammad Kamel',
            email: 'muhammad@example.com',
          ),
          const SizedBox(height: 16),
          const TilawaStatGroup(
            items: [
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
                onTap: _noop,
              ),
              TilawaListItem(
                icon: Icons.download_outlined,
                label: 'Downloads',
                showChevron: true,
                onTap: _noop,
              ),
            ],
          ),
          const TilawaSectionHeader(title: 'Preferences', quiet: true),
          TilawaListGroup(
            children: [
              TilawaListItem(
                icon: Icons.dark_mode_outlined,
                label: 'Dark mode',
                trailing: TilawaToggle(value: false, onChanged: (_) {}),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void main() {
  group('v2 screens', () {
    goldenTest(
      'Home',
      fileName: 'screens/home',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2ScreenConstraints,
        children: [
          GoldenTestScenario(
            name: 'top of feed',
            child: const V2MobileFrame(
              height: 800,
              child: _HomeScreen(),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'Player',
      fileName: 'screens/player',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2ScreenConstraints,
        children: [
          GoldenTestScenario(
            name: 'mid recitation',
            child: const V2MobileFrame(
              height: 800,
              child: _PlayerScreen(),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'Profile',
      fileName: 'screens/profile',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2ScreenConstraints,
        children: [
          GoldenTestScenario(
            name: 'main',
            child: const V2MobileFrame(
              height: 800,
              child: _ProfileScreen(),
            ),
          ),
        ],
      ),
    );
  });
}
