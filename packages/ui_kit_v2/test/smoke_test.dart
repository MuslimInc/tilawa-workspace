import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit_v2/tilawa_ui_kit_v2.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: buildTilawaMaterialTheme(),
    home: TilawaTheme.light(child: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('Btn renders all variants', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            TilawaBtn(label: 'Primary', onPressed: () {}),
            TilawaBtn(
              label: 'Ghost',
              variant: TilawaBtnVariant.ghost,
              onPressed: () {},
            ),
            TilawaBtn(
              label: 'Quiet',
              variant: TilawaBtnVariant.quiet,
              onPressed: () {},
            ),
            TilawaBtn(
              label: 'Inverse',
              variant: TilawaBtnVariant.inverse,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Ghost'), findsOneWidget);
    expect(find.text('Quiet'), findsOneWidget);
    expect(find.text('Inverse'), findsOneWidget);
  });

  testWidgets('atoms render', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            const TilawaAvatar(initials: 'MK'),
            const TilawaTag(label: 'New'),
            const TilawaNumBadge(number: 36),
            const TilawaProgressBar(value: 0.4),
            TilawaProgressRing(value: 0.6),
            const TilawaDivider(),
            TilawaToggle(value: true, onChanged: (_) {}),
            const TilawaDots(count: 4, activeIndex: 1),
            const TilawaSpinner(),
            const TilawaSkeleton(width: 100),
          ],
        ),
      ),
    );
    expect(find.text('MK'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
  });

  testWidgets('molecules render', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ListView(
          children: [
            const TilawaSearchField(),
            TilawaSurahRow(
              number: 1,
              name: 'Al-Fatihah',
              arabicName: 'الفاتحة',
              meta: 'Meccan · 7 verses',
              onTap: () {},
            ),
            TilawaReciterRow(
              name: 'Mishary Alafasy',
              meta: 'Hafs · Arabic',
              isSelected: true,
              onTap: () {},
            ),
            const TilawaSectionHeader(title: 'Surahs'),
            const TilawaEyebrow('Continue'),
            const TilawaListItem(label: 'Bookmarks', icon: Icons.bookmark),
            TilawaStatGroup(
              items: const [
                TilawaStatCard(value: '1', label: 'A'),
                TilawaStatCard(value: '2', label: 'B'),
                TilawaStatCard(value: '3', label: 'C'),
              ],
            ),
            const TilawaEmptyState(
              icon: Icons.bookmark_border,
              title: 'No bookmarks yet',
              body: 'Tap the bookmark icon on any verse to save it here.',
            ),
          ],
        ),
      ),
    );
    expect(find.text('Al-Fatihah'), findsOneWidget);
    expect(find.text('Mishary Alafasy'), findsOneWidget);
    expect(find.text('No bookmarks yet'), findsOneWidget);
  });

  testWidgets('organisms render', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Stack(
          children: [
            ListView(
              children: [
                const TilawaAppHeader(
                  greeting: 'Assalamu alaikum',
                  name: 'Muhammad',
                ),
                const TilawaLastReadHero(
                  eyebrow: 'Continue',
                  title: 'Al-Baqarah',
                  arabicTitle: 'البقرة',
                  subtitle: '49%',
                  progress: 0.5,
                  percentLabel: '49%',
                  onResume: _noop,
                ),
                TilawaPlayerHeader(
                  eyebrow: 'Now Reciting',
                  title: 'Al-Fatihah',
                  onBack: () {},
                ),
                const SizedBox(
                  height: 400,
                  child: TilawaVerseView(
                    verseArabic: 'بِسْمِ ٱللَّهِ',
                    translation: 'In the name of Allah.',
                    counterLabel: 'Ayah 1 of 7',
                  ),
                ),
                TilawaPlayerTransport(
                  progress: 0.5,
                  elapsed: '0:30',
                  remaining: '-1:00',
                  isPlaying: true,
                  onPlayPause: () {},
                  onPrevious: () {},
                  onNext: () {},
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: TilawaCompassRose(headingDegrees: 90),
                ),
                const TilawaProfileHero(
                  initials: 'M',
                  name: 'Muhammad',
                  email: 'm@example.com',
                ),
              ],
            ),
          ],
        ),
      ),
    );
    expect(find.text('Muhammad'), findsWidgets);
    expect(find.text('Al-Baqarah'), findsOneWidget);
  });

  testWidgets('BottomTabBar selection works', (tester) async {
    int idx = 0;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: TilawaBottomTabBar(
                items: const [
                  TilawaTabItem(label: 'Home', icon: Icons.home),
                  TilawaTabItem(label: 'Player', icon: Icons.play_arrow),
                ],
                currentIndex: idx,
                onChanged: (i) => setState(() => idx = i),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Player'));
    await tester.pumpAndSettle();
    expect(idx, 1);
  });
}

void _noop() {}
