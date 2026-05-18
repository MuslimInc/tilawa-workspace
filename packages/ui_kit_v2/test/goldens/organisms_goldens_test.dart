import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit_v2/tilawa_ui_kit_v2.dart';

import 'golden_constraints.dart';
import 'preview_wrapper.dart';

void _noop() {}

void main() {
  group('v2 organisms', () {
    goldenTest(
      'TilawaAppHeader',
      fileName: 'organisms/app_header',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2OrganismConstraints,
        children: [
          GoldenTestScenario(
            name: 'default · profile + search',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaAppHeader(
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
            ),
          ),
          GoldenTestScenario(
            name: 'minimal',
            child: const V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaAppHeader(
                greeting: 'Good morning',
                name: 'Muhammad',
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaBottomTabBar',
      fileName: 'organisms/bottom_tab_bar',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2OrganismConstraints,
        children: [
          GoldenTestScenario(
            name: '5 tabs · home active',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaBottomTabBar(
                items: const [
                  TilawaTabItem(label: 'Home', icon: Icons.home_filled),
                  TilawaTabItem(label: 'Player', icon: Icons.play_circle_fill),
                  TilawaTabItem(label: 'Qibla', icon: Icons.explore),
                  TilawaTabItem(label: 'Reciters', icon: Icons.mic_none),
                  TilawaTabItem(label: 'Profile', icon: Icons.person_outline),
                ],
                currentIndex: 0,
                onChanged: (_) {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: '5 tabs · profile active',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaBottomTabBar(
                items: const [
                  TilawaTabItem(label: 'Home', icon: Icons.home_filled),
                  TilawaTabItem(label: 'Player', icon: Icons.play_circle_fill),
                  TilawaTabItem(label: 'Qibla', icon: Icons.explore),
                  TilawaTabItem(label: 'Reciters', icon: Icons.mic_none),
                  TilawaTabItem(label: 'Profile', icon: Icons.person_outline),
                ],
                currentIndex: 4,
                onChanged: (_) {},
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaNowPlayingDock',
      fileName: 'organisms/now_playing_dock',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2OrganismConstraints,
        children: [
          GoldenTestScenario(
            name: 'playing',
            child: V2PreviewWrapper(
              child: SizedBox(
                width: 320,
                child: TilawaNowPlayingDock(
                  title: 'Surah Al-Fatihah',
                  subtitle: 'Mishary Alafasy',
                  progress: 0.34,
                  isPlaying: true,
                  onPlayPause: _noop,
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'paused · long title',
            child: V2PreviewWrapper(
              child: SizedBox(
                width: 320,
                child: TilawaNowPlayingDock(
                  title: 'Surah Al-Baqarah (The Cow) — a very long title',
                  subtitle: 'Maher Al Muaiqly · Hafs',
                  progress: 0.78,
                  isPlaying: false,
                  onPlayPause: _noop,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaLastReadHero',
      fileName: 'organisms/last_read_hero',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2OrganismConstraints,
        children: [
          GoldenTestScenario(
            name: 'mid · 49%',
            child: const V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaLastReadHero(
                eyebrow: 'Continue reading',
                title: 'Al-Baqarah',
                arabicTitle: 'البقرة',
                subtitle: 'Verse 142 · 49% complete',
                progress: 0.49,
                percentLabel: '49%',
                onResume: _noop,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'just started',
            child: const V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaLastReadHero(
                eyebrow: 'Continue reading',
                title: 'Al-Kahf',
                arabicTitle: 'الكهف',
                subtitle: 'Verse 1 · 1% complete',
                progress: 0.01,
                percentLabel: '1%',
                onResume: _noop,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'almost done',
            child: const V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaLastReadHero(
                eyebrow: 'Continue reading',
                title: 'Yā-Sīn',
                arabicTitle: 'يس',
                subtitle: 'Verse 81 of 83 · 97% complete',
                progress: 0.97,
                percentLabel: '97%',
                onResume: _noop,
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaPlayerHeader',
      fileName: 'organisms/player_header',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2OrganismConstraints,
        children: [
          GoldenTestScenario(
            name: 'default',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaPlayerHeader(
                eyebrow: 'Now Reciting',
                title: 'Surah Al-Fatihah · Mishary Alafasy',
                onBack: _noop,
                onMore: _noop,
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaVerseView',
      fileName: 'organisms/verse_view',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2ScreenConstraints,
        children: [
          GoldenTestScenario(
            name: 'first ayah (with Bismillah)',
            child: const V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 520,
                child: TilawaVerseView(
                  verseArabic: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
                  translation:
                      'All praise is for Allah—Lord of all worlds.',
                  counterLabel: 'Ayah 2 of 7',
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'mid-surah (no Bismillah)',
            child: const V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 460,
                child: TilawaVerseView(
                  showBismillah: false,
                  verseArabic: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
                  translation: 'You alone we worship, you alone we ask for help.',
                  counterLabel: 'Ayah 5 of 7',
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaPlayerTransport',
      fileName: 'organisms/player_transport',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2OrganismConstraints,
        children: [
          GoldenTestScenario(
            name: 'playing',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaPlayerTransport(
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
            ),
          ),
          GoldenTestScenario(
            name: 'paused · near end',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaPlayerTransport(
                progress: 0.92,
                elapsed: '2:14',
                remaining: '-0:12',
                isPlaying: false,
                onPlayPause: _noop,
                onPrevious: _noop,
                onNext: _noop,
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaCompassRose',
      fileName: 'organisms/compass_rose',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2OrganismConstraints,
        children: [
          GoldenTestScenario(
            name: 'pointing 112° NE',
            child: const V2PreviewWrapper(
              child: TilawaCompassRose(headingDegrees: 112),
            ),
          ),
          GoldenTestScenario(
            name: 'pointing N (0°)',
            child: const V2PreviewWrapper(
              child: TilawaCompassRose(headingDegrees: 0),
            ),
          ),
          GoldenTestScenario(
            name: 'pointing S (180°)',
            child: const V2PreviewWrapper(
              child: TilawaCompassRose(headingDegrees: 180),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaToast',
      fileName: 'organisms/toast',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2OrganismConstraints,
        children: [
          GoldenTestScenario(
            name: 'neutral',
            child: const V2PreviewWrapper(
              child: SizedBox(
                width: 320,
                child: TilawaToast(message: 'Bookmark added.'),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'success',
            child: const V2PreviewWrapper(
              child: SizedBox(
                width: 320,
                child: TilawaToast(
                  message: 'Surah downloaded.',
                  tone: TilawaToastTone.success,
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'error',
            child: const V2PreviewWrapper(
              child: SizedBox(
                width: 320,
                child: TilawaToast(
                  message: 'Couldn’t connect — try again.',
                  tone: TilawaToastTone.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaBottomSheet',
      fileName: 'organisms/bottom_sheet',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2OrganismConstraints,
        children: [
          GoldenTestScenario(
            name: 'reciter picker',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaBottomSheet(
                title: 'Choose a reciter',
                subtitle: 'Used as the default voice across the app.',
                footer: TilawaBtn(
                  label: 'Done',
                  expand: true,
                  onPressed: _noop,
                ),
                children: [
                  TilawaReciterRow(
                    name: 'Mishary Alafasy',
                    meta: 'Hafs · Arabic',
                    isSelected: true,
                    onTap: _noop,
                  ),
                  TilawaReciterRow(
                    name: 'Abdul Basit',
                    meta: 'Hafs · Arabic',
                    onTap: _noop,
                  ),
                  TilawaReciterRow(
                    name: 'Maher Al Muaiqly',
                    meta: 'Hafs · Arabic',
                    onTap: _noop,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaProfileHero',
      fileName: 'organisms/profile_hero',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2OrganismConstraints,
        children: [
          GoldenTestScenario(
            name: 'default',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaProfileHero(
                initials: 'M',
                name: 'Muhammad Kamel',
                email: 'muhammad@example.com',
                onEdit: _noop,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
