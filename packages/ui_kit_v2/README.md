# tilawa_ui_kit_v2

Atomic UI kit for Tilawa — a v2 rebuild of [`tilawa_ui_kit`](../ui_kit/) that
mirrors the Claude Design handoff bundle (the `tilawa-design-system` project).
Lives alongside the production kit so apps can migrate screen-by-screen.

## Layers

```
foundation/    tilawa_colors · tilawa_tokens · tilawa_typography · tilawa_theme
atoms/         Btn · IconBtn · Avatar · Tag · NumBadge · ProgressBar · ProgressRing
               Divider · Toggle · Spinner · Skeleton · Dots · Field
molecules/     SearchField · SurahRow · ReciterRow · SectionHeader · Eyebrow
               ListItem · ListGroup · StatCard · StatGroup · EmptyState
organisms/     AppHeader · BottomTabBar · NowPlayingDock · LastReadHero
               PlayerHeader · VerseView · PlayerTransport · CompassRose
               Toast · BottomSheet · ProfileHero
```

## Quick start

Wrap your subtree in `TilawaTheme.light` and either pass `buildTilawaMaterialTheme()`
to `MaterialApp`, or read the tokens directly via `TilawaTheme.of(context)`.

```dart
MaterialApp(
  theme: buildTilawaMaterialTheme(),
  home: TilawaTheme.light(
    child: HomeScreen(),
  ),
);
```

## Brand tokens

- **Primary** emerald `#2D5C3F` (palette `green500`–`green900`)
- **Accent** gold `#D4AF37` (palette `gold100`–`gold700`)
- **Sky** `#F0F9FF → #E0F2FE` — soft dawn-blue backdrop
- **Type** Alexandria (4 weights: 400/500/600/700) self-hosted from
  `assets/fonts/`. Amiri (via `google_fonts`) for Quranic verses only.
- **Radii** 6 / 8 / 12 / 16 / 20 / 32 / 40 / pill
- **Shadows** restrained, ambient (`el1`, `el2`, brand-tinted `glow`)
- **Motion** 150–300ms, `Curves.easeOut` default

## Gallery

```bash
cd packages/ui_kit_v2/example
flutter run
```

See [`example/lib/main.dart`](example/lib/main.dart) for a 5-tab gallery
(Home · Player · Qibla · Reciters · Profile) composed entirely from the kit.

## Tests

```bash
cd packages/ui_kit_v2
flutter test
```
